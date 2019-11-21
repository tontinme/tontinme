# About ceph notes

- [librbd feature list](#librbd feature list)
- [ceph pg stat](#ceph pg stat)
- [snapshot与clone](#snapshot与clone)
- [ceph读写流程介绍](#ceph读写流程介绍)
- [ceph bucket reshard](#ceph bucket reshard)
- [故障与数据恢复](#故障与数据恢复)


## librbd feature list

* layering

    image的克隆操作。可以对image创建快照并保护，然后从快照克隆出新的image出来，父子image之间采用COS技术，共享对象数据

* striping v2

    条带化对象数据，类似raid0，可以改善顺序读写场景较多情况下的性能

* exclusive lock

    保护image数据一致性，对image做修改时，需要持有此锁。这个可以看做是一个分布式锁，在开启的时候，确保只有一个客户端在访问image，否则锁的竞争会导致io急剧下降。主要应用场景是qemu live-migration

* object map

    此特性依赖于exclusive lock。因为image的对象分配是thin-provisioning，此特性开启时，会记录image所有对象的一个位图，用以标记对象是否真的存在，在一些场景下可以加速io

* fast diff

    此特性依赖于object map和exclusive lock。快速比较image的snapshot之间的差异

* deep-flatten
    layering特性使得克隆image的时候，父子image之间采用COS，他们之间的对象文件存在依赖关系。
    flatten操作的目的是解除父子image的依赖关系，但是子image的快照并没有解除依赖，deep-flatten特性使得快照的依赖也解除

* journaling

    依赖于exclusive lock。将image的所有操作进行日志化，并且复制到另外一个集群(mirror)，可以做到块存储的异地灾备。这个特性在部署的时候需要新部署一个daemon进程，这个特性很重要，可以做跨集群/机房容灾。即rbd-mirror

## ceph pg state

### 介绍

volume -> object -> pg -> osd

ceph中volume被分成很多小的object(默认4MB)，存储在pg中。
通过如下命令获得一个volume对应的objects。

1. 通过rbd info获得block prefix
2. 通过rados ls获得具体的object名称
3. 通过ceph osd map获得object对应的pg和osd

```
root@njA-m02-mon-01:~# rbd -p volumes info volume-5d451798-920f-4316-a129-9af82bd71349
rbd image 'volume-5d451798-920f-4316-a129-9af82bd71349':
	size 10240 MB in 2560 objects
	order 22 (4096 kB objects)
	block_name_prefix: rbd_data.f3516d238e1f29
	format: 2
	features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
	flags:

root@njA-m02-mon-01:~# rados -p volumes ls | grep '^rbd_data.f3516d238e1f29' | head -n5
rbd_data.f3516d238e1f29.00000000000001fe
rbd_data.f3516d238e1f29.000000000000018a
rbd_data.f3516d238e1f29.0000000000000210
rbd_data.f3516d238e1f29.000000000000022d
rbd_data.f3516d238e1f29.00000000000002c4
...

root@njA-m02-mon-01:~# ceph osd map volumes rbd_data.f3516d238e1f29.00000000000001fe
osdmap e1930 pool 'volumes' (2) object 'rbd_data.f3516d238e1f29.00000000000001fe' -> pg 2.f6454000 (2.0) -> up ([215,184,208], p215) acting ([215,184,208], p215)

# 可知示例的object在pg 2.0中，对应的osd为215，184，208

root@njA-m02-mon-01:~# ceph osd find 215
{
    "osd": 215,
    "ip": "10.131.134.12:6806\/990178",
    "crush_location": {
        "copy-set": "cs01",
        "host": "njA-m02-osd-03",
        "host-group": "cs01-hg01",
        "root": "apple"
    }
}

root@njA-m02-osd-03:~# cd /var/lib/ceph/osd/ceph-215/current/2.0_head/
root@njA-m02-osd-03:/var/lib/ceph/osd/ceph-215/current/2.0_head# ls
__head_00000000__2                                           rbd\udata.d241ff238e1f29.00000000000001d5__head_F65EC000__2
rbd\udata.b98651238e1f29.00000000000001f3__head_21C80000__2  rbd\udata.f3516d238e1f29.00000000000001fe__head_F6454000__2
root@njA-m02-osd-03:/var/lib/ceph/osd/ceph-215/current/2.0_head# du -sh rbd\\udata.f3516d238e1f29.00000000000001fe__head_F6454000__2
4.0M	rbd\udata.f3516d238e1f29.00000000000001fe__head_F6454000__2
```

### pg状态说明

* inactive - The placement group has not been active for too long (i.e., it hasn’t been able to service read/write requests).
* unclean - The placement group has not been clean for too long (i.e., it hasn’t been able to completely recover from a previous failure).
* stale - The placement group status has not been updated by a ceph-osd, indicating that all nodes storing this placement group may be down.
* degraded - 一般和undersized同时出现。指有osd故障时，ceph将该osd上的所有pg标记为degraded（多副本情况）。
* peered - pg协商osd失败。可能是pool的min_size大于存活的osd数量。
* peering - 一个pg下的所有osd进行状态协商，同意该pg下的所有objects保持一个最新版本。需要注意的是，这只是认同最新版，不代表这些osd都存储该最新版. 新建pg或者重启osd时，都会触发对应pg的peering状态。peering结束后, 会进入active状态，或者recovering
* remapped - remapped+backfilling。pg被map到另一组osd中了。osd out时，会对受影响的pg充分配，就会出现该状态。
* recover - recover+inconsistent。scrub失败时，或者有osd恢复期间，其他osd有新数据写入，都会出现这种情况，即各osd上的副本不一致
* undersized - pg副本数不足
* incomplete - Ceph detects that a placement group is missing information about writes that may have occurred, or does not have any healthy copies. If you see this state, try to start any failed OSDs that may contain the needed information or temporarily adjust min_size to allow recovery.
* repair - Ceph is checking the placement group and repairing any inconsistencies it finds (if possible).
* splitting - Ceph is splitting the placement group into multiple placement groups. (functional?)
* replay - The placement group is waiting for clients to replay operations after an OSD crashed.

### 找出有问题的pg

    ceph pg dump_stuck [unclean|inactive|stale|undersized|degraded]

### osd需要其他副本osd告知应该拥有哪些objects，因此对于单副本的objects，需要强制通知primary osd创建pg

    ceph osd force-create-pg <pgid>

### 通过query命令查看pg的状态

```
    ceph pg <pg_id> query

    { "state": "down+peering",
      ...
      "recovery_state": [
           { "name": "Started\/Primary\/Peering\/GetInfo",
             "enter_time": "2012-03-06 14:40:16.169679",
             "requested_info_from": []},
           { "name": "Started\/Primary\/Peering",
             "enter_time": "2012-03-06 14:40:16.169659",
             "probing_osds": [
                   0,
                   1],
             "blocked": "peering is blocked due to down osds",
             "down_osds_we_would_probe": [
                   1],
             "peering_blocked_by": [
                   { "osd": 1,
                     "current_lost_at": 0,
                     "comment": "starting or marking this osd lost may let us proceed"}]},
           { "name": "Started",
             "enter_time": "2012-03-06 14:40:16.169513"}
       ]
    }
```

### pg down + failed peering

可能是有osd坏掉，可以

    ceph osd lost 1     # lost命令会清除该osd的数据, mark osd as permanently lost

### unfound objects

    ceph pg 2.4 list_missing [starting offset, in json]

如果确认数据无法找到，可以删除objects或者回滚数据

    ceph pg <pg_id> mark_unfound_lost revert|delete

    The “delete” option will forget about them entirely.
    The “revert” option (not available for erasure coded pools) will either roll back to a previous version of the object or (if it was a new object) forget about it entirely.

### homeless pg

pg所在的所有osd都挂了

    ceph health
    HEALTH_WARN 24 pgs stale; 3/300 in osds are down

### pg inconsistent

可能是scrub过程中出现了error

    $ ceph health detail
    HEALTH_ERR 1 pgs inconsistent; 2 scrub errors
    pg 0.6 is active+clean+inconsistent, acting [0,1,2]
    2 scrub errors

    ceph pg repair <pg_id>

## snapshot与clone

ceph默认使用cow(copy on write)创建快照。

> cow - copy on write. 对快照进行首次修改时，先读取源数据，并写到新位置，再更新源数据，一次读两次写，写性能不好
> row - redirect on write. 对快照首次修改时，先读取源数据，然后直接将变更写到新位置，将指针移到新位置，避免了写放大，但是数据放在多个快照上，碎片化严重，因此读性能不行，写性能好.

nova创建虚拟机使用rbd clone技术

> snapshot - 基于cow，快照为只读
> clone - 基于cow，基于快照创建可读可写的新卷

新创建的clone为空，当写数据时，直接上溯到快照（一直到源镜像），拷贝到本地后再进行写操作。由于这里对源镜像只进行读操作，因此使用cow性能更好。
但是如果base snapshot已经有多个快照的话，依然会有性能问题

## ceph读写流程介绍

客户端使用rbd的两个方式

> kernel rbd: 创建rbd设备后，将其map到内核中,形成一个虚拟的块设备(/dev/rbd0)。
> librbd: 创建rbd设备后，通过调用librbd接口，实现对rbd设备的访问。librbd对二进制分块，默认为4M大小，librbd调用librados将对象写入集群

librados将数据首先写入primary osd，primary osd发送写请求给其他secondary osd。之后三副本的osd执行相同的操作。先写pglog(类似sql中的undo log，用于回滚)，再写磁盘（如果有journal，则先写journal即返回ack）。secondary osd写完后发送ack给primary osd， primary osd确认所有osd写完后，返回client写入成功。



## ceph bucket reshard

rados的一个特性是不保存系统的全部对象索引，而是使用crush算法，通过对象的名字、集群的配置和状态来计算存储位置。这大大提高了ceph的扩展性，总的IO能力会随着系统中osd的数量增加而增加，原因是在进行IO操作时，不需要查询全局的元数据。

然而rgw还是为每个bucket维护了一份索引，该索引以omap形式记录这个bucket下对象元数据信息。索引的作用，包括遍历bucket中全部对象，版本控制的对象维护日志、多数据中心同步，存储桶审计功能等。每个存储桶的索引也是一个rados对象，存放在index存储池，最终会存放在这个rados对象对应的osd的leveldb这个kv数据库上。bucket索引不会影响对象的读操作，但对写和修改会增加一些额外的操作。

主要影响两个方面，一是在单个bucket索引对象上能存储的数据总量有限，默认情况下，每个bucket只有一个索引对象，超大的索引对象会造成性能和可靠性问题，极端情况下，可能造成osd进程挂掉(早期设计问题，list请求会导致迭代器遍历整个leveldb，直到事务完成，才释放内存，如果对象过多，会导致level所在osd的内存吃紧，进而崩溃退出)。二是造成了性能瓶颈，因为所有对同一个bucket的写操作，都会对一个索引对象做修改和序列化操作。

H版本开始支持bucket分片功能(bucket sharding)，可以将索引分成多个分片，放在不同osd上，后来又增加了允许修改bucket索引分片的命令，但是reshard过程中，bucket无法进行写操作（同样，由于元数据变化，也无法进行multisite 复制）。L版引进了动态bucket分片，现在随着存储对象的增加，bucket可以自动分片了，且不会影响bucket的IO操作（但是实际效果待验证）

bucket没有目录树的概念，如果要获取某个虚拟目录下的孩子信息，那么需要遍历以这个虚拟目录地址为prefix的所有对象，这样过滤一遍会很慢

手动分片的命令

```
$ radosgw-admin reshard add --bucket=<bucket> --num-shards=<num_shards>
$ radosgw-admin reshard list
$ radosgw-admin reshard process
```

由于动态reshard效果不好，建议进行如下调优

1. 关闭动态resharding. 避免自动reshard导致bucket不可写
2. 预估单个bucket存放的对象数量，按照每个shard十万数据，提前做好分片。这样后期也不需要手动reshard了

## 故障与数据恢复

link: https://cloud.tencent.com/developer/article/1529095

pglog类似于数据库的undo log, 一般只保留最近几千条的操作记录。但是当pg处于degraded时，pglog会保存更多的日志条目，期望在osd恢复后用来恢复数据.

下线后, monitor重新计算该osd拥有的primary pg, 并通知该pg所有的osd，pg设置为degraded状态，pglog增加条目.

1. 如果一段时间内（默认好像是5min，线上改成了12h），osd重新上线. 

1.1 osd通知monitor并注册，上线前会读取自己的pglog

1.2 monitor通知osd，继续使用之前的osd id和pg分配，通知degraded状态的pg，重新加入该osd

1.3.1 如果pg的primary osd是该osd，那么需要查询pginfo给对应的replicate osd（临时的primary）. primary osd通过合并pglog，处理missing列表，恢复完成后，标记权威log，变成active状态

1.3.2 如果pg的replicate osd是该osd，当接到primary的请求后，返回自己的pginfo和pglog，并获得primary的missing列表。此时primary pg标记为active

1.4 active后，开始接收IO请求。但是故障osd的数据依然是过期的。primary pg发送pull请求从replicate获得最新数据. replicate p接收primary pg的push请求来恢复数据

1.5 恢复完成后，pg标记为clean状态

其中1.3是唯一不处理请求的阶段。通常会在1s以内完成来减少不可用时间. 但是也有其他问题，比如要读取的数据刚好在missing列表中，那么pg恢复会进行"插队"，提前恢复这部分数据，这种情况的延迟大概在几十毫秒。

2. 如果osd永久故障

比如N天之后才重新上线故障osd，这时已经不能通过pglog进行数据恢复，就需要backfill(全量拷贝)了。

步骤和以上流程基本一致，有区别的是1.3.

2.3.1 如果故障osd拥有primary pg, 该pg在对比pglog后发现自己需要backfill，它会发送请求给monitor，临时将replicate置为primary pg。等自己完全恢复了才会接管primary角色。

2.3.2 故障osd拥有replicate角色，该pg的primary osd会发起backfill流程向该osd复制数据，这时不影响正常IO处理

## ceph df容量计算

```
[root@test01 ~]# ceph osd df
ID CLASS WEIGHT  REWEIGHT SIZE    RAW USE DATA   OMAP   META     AVAIL   %USE  VAR  PGS STATUS
 0   hdd 0.06740  1.00000  69 GiB  17 GiB 16 GiB 15 KiB 1024 MiB  52 GiB 25.07 0.81 232     up
 1   hdd 0.04790  1.00000  49 GiB  17 GiB 16 GiB 15 KiB 1024 MiB  32 GiB 35.31 1.14 232     up
 2   hdd 0.04790  1.00000  49 GiB  17 GiB 16 GiB 15 KiB 1024 MiB  32 GiB 35.31 1.14 232     up
                    TOTAL 167 GiB  52 GiB 49 GiB 47 KiB  3.0 GiB 115 GiB 31.08

[root@test01 ~]# ceph df
RAW STORAGE:
    CLASS     SIZE        AVAIL       USED       RAW USED     %RAW USED
    hdd       167 GiB     115 GiB     49 GiB       52 GiB         31.08
    TOTAL     167 GiB     115 GiB     49 GiB       52 GiB         31.08

POOLS:
    POOL                           ID     STORED      OBJECTS     USED        %USED     MAX AVAIL
    cephfs_data                     1      22 MiB           9      67 MiB      0.07        33 GiB
    cephfs_metadata                 2     139 KiB          23     2.1 MiB         0        33 GiB
    volume                          7      16 GiB       4.17k      49 GiB     32.83        33 GiB
    default.rgw.buckets.index       8         0 B           1         0 B         0        33 GiB
    default.rgw.buckets.data        9      36 MiB          12     109 MiB      0.11        33 GiB
    default.rgw.buckets.non-ec     10         0 B           0         0 B         0        33 GiB
```

max avail的计算方法

MAX AVAIL = GLOBAL.SIZE * ( full_ratio - MAX(ceph osd df used%)) / replication_size

由于crush分配并不均匀，实际计算时，选择使用量最大的那个osd作为整个集群的利用率。

假如full_ratio=0.95，最大osd使用率为35%，则max avail为

167 * ( 0.95 - 0.35 ) / 3 = 33.4GB





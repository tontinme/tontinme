# About ceph notes

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
> row - redirect on write. 对快照首次修改时，先读取源数据，然后直接将变更写到新位置，将指针移到新位置，避免了写放大，但是数据放在多个快照上，碎片化严重，因此读性能不行，写性能好

nova创建虚拟机使用rbd clone技术

> snapshot - 基于cow，快照为只读
> clone - 基于cow，基于快照创建可读可写的新卷

新创建的clone为空，当写数据时，直接上溯到快照（一直到源镜像），拷贝到本地后再进行写操作。由于这里对源镜像只进行读操作，因此使用cow性能更好。
但是如果base snapshot已经有多个快照的话，依然会有性能问题






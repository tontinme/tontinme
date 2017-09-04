# Ceph

下面步骤是简单的Ceph排查指南，附件是更深入的查看Ceph内部状态的指南。

1. 检查management和storage的网络的健康情况。
2. 使用 ceph -s 命令或者是 ceph health detail命令查看Ceph集群是否有问题。
3. 假如发觉某个OSD有异常，可以通过查看这个osd的日志找出具体原因。
4. 先把所有OSD的osd_op_complaint_time设置为1秒，用于查看是否有slow request。

  ```
  #  for i in `seq 0 20`; do ceph tell osd.$i injectargs --osd_op_complaint_time 1; done
  ```

5. 持续观察ceph的状态，使用 ceph -w 命令查看。
6. 先关闭scrub和deep-scrub，避免scrub对测试产生影响。

  ```
  # ceph osd set noscrub
  # ceph osd set nodeep-scrub
  ```

7. 在你要测试的pool上创建一个10G的rbd image。
8. 使用rbd bench-write直接压测ceph，避免在虚拟机上测试的干扰，并用ceph -w查看集群状态。

  ```
  # 测试4k随机写IOPS
  # rbd -p volumes bench-write zhurongze-test  --io-size 4096 --io-threads 256 --io-total 10737418240 --io-pattern rand
  # 测试128K随机写带宽
  # rbd -p volumes bench-write zhurongze-test  --io-size 131072 --io-threads 256 --io-total  10737418240 --io-pattern rand
  ```

9. 在测试过程中，使用iostat -x -m 1命令查看每个OSD硬盘的await和util，检查是否有异常。
10. 在测试过程中，使用top命令，或者mpstat命令，检查CPU负载情况，查看CPU是否是瓶颈。

  ```
  #mpstat -P ALL  1
  ```

11. 在测试过程中，查看内存使用情况。

## Ceph Debug Tips

查看osd配置

  ceph daemon osd.438 config show | less

## 修复osd

新建raid0

```
sudo ssacli ctrl slot=0 create type=ld drives=1I:1:13 raid=0
```

先格式化分区

```
sudo dd if=/dev/zero of=/dev/sdf bs=1M count=100
sudo ceph-disk --log-stdout -v zap /dev/sdf
```

准备osd

```
# 找到uuid
ceph osd dump | grep 'osd.680'
# 执行prepare
sudo ceph-disk --log-stdout -v prepare /dev/sdf --osd-uuid 669f35ef-f53f-413f-9bda-e4510dd1adca
```

启动osd

```
# 新盘，需要重新认证
ceph auth del osd.680
# 启动osd
sudo ceph-disk --log-stdout -v activate /dev/sdf1
```

格式化的详细输出
```
[onest@BFJD-PSC-oNest-Sst-SV22 ~]$ sudo ceph-disk --log-stdout -v zap /dev/sdc
get_dm_uuid: get_dm_uuid /dev/sdc uuid path is /sys/dev/block/8:32/dm/uuid
zap: Zapping partition table on /dev/sdc
command_check_call: Running command: /sbin/sgdisk --zap-all -- /dev/sdc
Creating new GPT entries.
GPT data structures destroyed! You may now partition the disk using fdisk or
other utilities.
command_check_call: Running command: /sbin/sgdisk --clear --mbrtogpt -- /dev/sdc
Creating new GPT entries.
The operation has completed successfully.
update_partition: Calling partprobe on zapped device /dev/sdc
command_check_call: Running command: /usr/bin/udevadm settle --timeout=600
command: Running command: /usr/bin/flock -s /dev/sdc /sbin/partprobe /dev/sdc
command_check_call: Running command: /usr/bin/udevadm settle --timeout=600
```

```
949  sudo dd if=/dev/zero of=/dev/sdf bs=1M count=100
 950  sudo ceph-disk --log-stdout -v zap /dev/sdf
 951  sudo ceph-disk --log-stdout -v prepare /dev/sdf --osd-uuid 71dd2628-5c72-47f8-935c-79bf80d36de1
 952  lsblk
 953  sudo ceph-disk --log-stdout -v activate /dev/sdf1
 954  lslk
 955  lsblk
 956  sudo dd if=/dev/zero of=/dev/sdn bs=1M count=100
 957  sudo ceph-disk --log-stdout -v zap /dev/sdn
 958  sudo ceph-disk --log-stdout -v prepare /dev/sdn --osd-uuid 6dbcae9f-861e-4163-9cb5-27fe65097309
 959  sudo ceph-disk --log-stdout -v activate /dev/sdn1
 960  lsblk
 961  sudo dd if=/dev/zero of=/dev/sdr bs=1M count=100
 962  sudo ceph-disk --log-stdout -v zap /dev/sdr
 963  sudo ceph-disk --log-stdout -v prepare /dev/sdr --osd-uuid 7959b57b-9543-4a47-967b-3bf492754a0e
 964  sudo ceph-disk --log-stdout -v activate /dev/sdr1
 965  lsblk
 966  sudo dd if=/dev/zero of=/dev/sdk bs=1M count=100
 967  sudo ceph-disk --log-stdout -v zap /dev/sdk
 968  sudo ceph-disk --log-stdout -v prepare /dev/sdk --osd-uuid 68d5b5fc-606b-4d4e-be6b-a53d6c2be693
 969  sudo ceph-disk --log-stdout -v activate /dev/sdk1
 970  lsblk
 971  sudo ssacli ctrl slot=0 ld all show detail
 972  sudo ssacli ctrl slot=0 ld 11 show detail
 973  sudo [Cumount /var/lib/ceph/osd/ceph-768
 974  sudo umount /var/lib/ceph/osd/ceph-768
 975  sudo ssacli ctrl slot=0 ld 11 delete
 976  sudo ssacli ctrl slot=0 pd all show detail
 977  sudo ssacli ctrl slot=0 create type=ld drives=2I:1:11 raid=0
 978  sudo ssacli ctrl slot=0 ld 11 show detail
 984  lsblk
 ```



 ```
1009  cd zhu/
1010  ceph auth get osd.2
1011  ceph auth get osd.2 > osd.468.keyring
1012  vim osd.468.keyring
1013  sudo ceph -s
1014  ll /etc/ceph/
1015  cat /etc/ceph/ceph.client.admin.keyring
1016  sudo ceph auth get client.admin
1017  sudo ceph auth add osd.468 -i osd.468.keyring
1018  sudo ceph auth get osd.468


26  cat /var/lib/ceph/osd/ceph-468/keyring
27  sudo cat /var/lib/ceph/osd/ceph-468/keyring
28  exit
29  systemctl status ceph-osd@468
30  sudo systemctl restart ceph-osd@468
31  systemctl status ceph-osd@468
 ```



我用  sudo ceph daemon osd.1537 dump_historic_ops 命令把发生slow request的osd的最近最差op dump出来
发现主要是在sub_op_committed和sub_op_applied之间相差很大

```
[onest@BFJD-PSC-oNest-Sst-SV121 ~]$ sudo ceph daemon osd.463  dump_historic_ops
...
"type_data": [
    "started",
    [
        {
            "time": "2016-12-06 23:43:38.753992",
            "event": "initiated"
        },
        {
            "time": "2016-12-06 23:43:38.754194",
            "event": "queued_for_pg"
        },
        {
            "time": "2016-12-06 23:43:38.754874",
            "event": "reached_pg"
        },
        {
            "time": "2016-12-06 23:43:38.754886",
            "event": "started"
        },
        {
            "time": "2016-12-06 23:43:38.757241",
            "event": "commit_queued_for_journal_write"
        },
        {
            "time": "2016-12-06 23:43:38.757296",
            "event": "write_thread_in_journal_buffer"
        },
        {
            "time": "2016-12-06 23:43:38.757687",
            "event": "journaled_completion_queued"
        },
        {
            "time": "2016-12-06 23:43:38.757816",
            "event": "sub_op_committed"
        },
        {
            "time": "2016-12-06 23:43:42.437672",
            "event": "sub_op_applied"
        },
        {
            "time": "2016-12-06 23:43:42.437698",
            "event": "done"
        }
    ]
]
}
]
}

```

## 在ubuntu 14.04给ceph 使用perf 和火焰图

快速使用方法
```
root@node-289:~/zhu# perf record -p 2612463
^C[ perf record: Woken up 40 times to write data ]
[ perf record: Captured and wrote 16.774 MB perf.data (~732860 samples) ]
root@node-289:~/zhu# perf report
root@node-289:~/zhu#
```

安装ceph debuginfo

```
# apt-get install ceph-dbg ceph-common-dbg
```

下载brendan的火焰图生成程序

```
# git clone https://github.com/brendangregg/FlameGraph  
```

记录CPU

```
# perf record -e cpu-clock --call-graph dwarf -p 1857681 -- sleep 30
```

会自动生成 perf.data 文件

```
# perf script | ../FlameGraph/stackcollapse-perf.pl > rgw-perf.out
```

生成火焰图

```
# ../FlameGraph/flamegraph.pl rgw-perf.out > perf-rgw.svg
```

用浏览器打开, 点击具体进程可以查看详情
示例图形
解决tcmalloc问题之前
![bad case](./bad-perf-rgw.svg)
解决tcmalloc问题之后
![good case](./good-perf-rgw.svg)


## ceph osd near full

1. ceph pg dump > /tmp/ori.pgdump

2. ceph osd df

weight   ...  reweight


3. ceph osd reweight [X] [Y]
OR
ceph osd crush reweight [X] [Y]

4. ceph -s


自动调整osd数据分布
Reweights all the OSDs by reducing the weight of OSDs which are heavily overused. By default it will adjust the weights downward on OSDs which have 120% of the average utilization, but if you include threshold it will use that percentage instead

```
ceph osd reweight-by-utilization
```

## MOS Ceph 替换journal

    # 停止osd
    stop ceph-osd id=50
    # 刷新journal到磁盘
    ceph-osd --flush-journal -i 50
    # 查看journal指向的磁盘
    ll
    # unlink
    unlink journal
    ll /dev/disk/by-partuuid/a50517e1-080b-4465-9791-073e2f8506b9
    # 用新盘重新link
    ln -s /dev/disk/by-partuuid/8b48109d-ee7d-48b3-a31e-0938a8a4e1a5 journal
    ceph-osd --mkjournal -i 50
    # 启动osd
    start ceph-osd id=50
    # 清除旧journal数据
    dd if=/dev/zero of=/dev/disk/by-partuuid/a50517e1-080b-4465-9791-073e2f8506b9 bs=1M count=100
    ll
    ll /dev/disk/by-partuuid/8b48109d-ee7d-48b3-a31e-0938a8a4e1a5
    # 检查集群状态
    ceph -s
    lsblk

如果需要新建journal分区，操作步骤如下

    # 查看journal磁盘当前情况
    sgdisk --print /dev/sdv
    # 根据末位标记新建分区
    sgdisk -n 8:0:+10G -c 8:'primary' /dev/sdv
    ll /dev/disk/by-partuuid/ | grep sdv8
    sgdisk --print /dev/sdv
    lsblk
    # 通知系统，识别新分区
    partprobe /dev/sdv
    lsblk
    sgdisk --print /dev/sdv


ssd 替换journal

ssd使用当前磁盘做journal即可。即在本地创建一个journal文件，作为journal使用。

先保存当前的journal分配信息

    cd /var/lib/ceph/osd/
    for i in `ls .`; do ls -l $i/journal; done > ~/c2-journal
    vim ~/c2-journal
    ls -l /dev/disk/by-partuuid/ | grep -e 'sdt' -e 'sdu' -e 'sdv' | sort -k 11
    ls -l /dev/disk/by-partuuid/ | grep -e 'sdt' -e 'sdu' -e 'sdv' | sort -k 11 >> ~/c2-journal
    # 编辑文件，记录当前的journal分配信息
    vim ~/c2-journal
    lsblk

这里ceph-9为ssd类型的osd，之前使用sdv为journal盘，现在替换为本地

    cd ceph-9
    ll
    # 停止osd，并将journal刷入磁盘
    stop ceph-osd id=9
    ceph-osd --flush-journal -i 9
    ll
    unlink journal
    # 在本地创建2GB的磁盘分区
    dd if=/dev/zero of=/var/lib/ceph/osd/ceph-9/journal bs=1M count=2048
    ll
    ceph-osd --mkjournal -i 9
    start ceph-osd id=9
    # 清除旧journal的数据
    dd if=/dev/zero of=/dev/disk/by-partuuid/d0f88ce2-7c7d-4cd5-9852-f6b839c2e313 bs=1M count=100
    ceph -s

## ceph动态调整参数，debug

方法一

    ceph tell osd.11 injectargs --debug-osd 5/5

方法二

    ceph daemon osd.11 config set debug_osd 0/0

## fio测试

rbd写满磁盘

```
fio --size=100% --ioengine=rbd --direct=1 --thread=1 --numjobs=1 --rw=write --name=writefile --bs=1m --pool=test --iodepth=200  --direct=1 --sync=0 --randrepeat=0 --refill_buffers --end_fsync=1 --rbdname=1TB_test_image_1 --group_reporting
```

## 创建测试pool，测试osd性能

### 创建单盘osd的pool

先获得当前crushmap

root@Ceph-P-1:~# ceph osd getcrushmap -o /tmp/p.bin
got crush map from osdmap epoch 2634
root@Ceph-P-1:~# crushtool -d /tmp/p.bin -o /tmp/p.bin.txt

root@Ceph-P-2:~# ceph osd crush add-bucket only-a-osd root
added bucket only-a-osd type root to crush map
root@Ceph-P-2:~# ceph osd crush add osd.61 1 root=only-a-osd
add item id 61 name 'osd.61' weight 1 at location {root=only-a-osd} to crush map

root@Ceph-P-2:~# ceph osd crush rule create-simple only_a_osd_ruleset only-a-osd osd

root@Ceph-P-1:~# ceph osd crush rm only-a-osd
Error ENOTEMPTY: (39) Directory not empty
root@Ceph-P-1:~# ceph osd crush rm osd.61 only-a-osd
removed item id 61 name 'osd.61' from crush map
root@Ceph-P-1:~# ceph osd tree

root@Ceph-P-1:~# ceph osd crush move osd.61 1 root=only-a-osd
Error EINVAL: (22) Invalid argument
root@Ceph-P-1:~# ceph osd crush create-or-move osd.61 1 root=only-a-osd
create-or-move updating item name 'osd.61' weight 1 at location {root=only-a-osd} to crush map

root@Ceph-P-1:~# ceph osd pool create a-osd-pool 64 64
pool 'a-osd-pool' created
root@Ceph-P-1:~# ceph osd pool set a-osd-pool size 1
set pool 27 size to 1
root@Ceph-P-1:~# ceph osd pool set a-osd-pool crush_ruleset 1
set pool 27 crush_ruleset to 1
root@Ceph-P-1:~# ceph osd dump  |grep pool

root@Ceph-P-1:~# rbd -p a-osd-pool create --image test_image --size 51200
root@Ceph-P-1:~# rbd -p a-osd-pool create info test_image
rbd: too many arguments
root@Ceph-P-1:~# rbd -p a-osd-pool info test_image
rbd image 'test_image':
        size 51200 MB in 12800 objects
        order 22 (4096 kB objects)
        block_name_prefix: rbd_data.13565574b0dc51
        format: 2
        features: layering, exclusive-lock, object-map, fast-diff, deep-flatten
        flags:


# 换盘流程
https://mp.weixin.qq.com/s?__biz=MzI0NDE0NjUxMQ==&mid=2651256423&idx=1&sn=b0cc580db2d9c090f96ea46f741fee25&chksm=f2901e47c5e79751b45f9003b9a72629357e7243d5dfcb0570a77fc782f40a2af274e8bd867e&mpshare=1&scene=1&srcid=061968OlUHGz4P8SSIurb1sT&key=2b4a905e8c07cb21bc512fb21bd3ea3e33f1565f18b4a7bd9166803133b0727e8b679329a1a224e09bbe40499af33e8fe029407c35c8ff30e1fe2ad3d1b8475e1ed994df1b592159e3b30417182191b1&ascene=0&uin=MTU1OTUyMzc1&devicetype=iMac+MacBookPro12%2C1+OSX+OSX+10.12.5+build(16F73)&version=12020810&nettype=WIFI&fontScale=100&pass_ticket=IsbxGZXfR2MpL0vfwotdOU%2F%2Fs0Q0bDwBtLhZVkmq9TQ%3D

磁盘故障后，OSD 需要被替换
管理员需要重新部署新的 OSD
这两步骤需要在最小数据迁移情况下进行，同时需要让原来的 OSD 在原来的 CRUSH 层次中。

流程

1. ceph osd destroy N --yes-i-really-mean-it
用于移除 OSD 私有配置，比如加密密钥，cephx key，同时这个命令用于确保后续的 prepare 没有误操作正在使用的 OSD
2. ceph-disk prepare /dev/sdN --replace-osd-id X
ceph-disk 会使用一个新的 MON 命令， 'osd new'同时接受一些参数
 * uuid
 * replace-id 
 * secret
 * config-key key/value pairs


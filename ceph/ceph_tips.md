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

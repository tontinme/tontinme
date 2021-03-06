Table of Contents

[rpm制作源签名](rpm制作源签名)
[linux设置高级路由](linux设置高级路由)
[BPF和eBPF](BPF和eBPF)

# rpm制作源签名

[link](https://gist.github.com/fernandoaleman/1376720/aaff3a7a7ede636b6913f17d97e6fe39b5a79dc0)

1. 生成key或者导入key

    gpg --gen-key  # 选项都默认即可，需要填写用户名和邮箱
    gpg --list-keys

一个技巧是通过

    ping -f ip

来增加熵，ip 为执行 gpg 时所在机器的 IP 地址。 gpg 命令成功执行后可以通过

或者导入key。公钥和私钥都需要导入
    
    # public key
    gpg --import RPM-GPG-KEY-umcloud
    # private key
    gpg --allow-secret-key-import --import secret-umcloud
    gpg --list-secret-key

附：导出公钥，私钥

    # public key
    gpg --export -a 'umcloud' > RPM-GPG-KEY-umcloud
    # private key
    gpg --export-secret-key -a umcloud > secret-umcloud

    import或者delete公钥私钥时，如果遇到如下错误。那么需要
    安装pinentry-gtk或者pinentry-qt, 然后在gpg-agent中指定pinentry路径
    # cat ~/.gnupg/gpg-agent.conf
        allow-preset-passphrase
        pinentry-program /usr/bin/pinentry-curses

    This is a secret key! - really delete? (y/N) y
    gpg: deleting secret key failed: No pinentry
    gpg: deleting secret subkey failed: No pinentry
    gpg: umstor001: delete key failed: No pinentry

    [root@umstor-repo utils]# gpg --allow-secret-key-import --import secret-umstor
    gpg: key 4330CA6A5F7819A6: "umstor001 <umstor001@umcloud.com>" not changed
    gpg: key 4330CA6A5F7819A6/4330CA6A5F7819A6: error sending to agent: No pinentry
    gpg: error building skey array: No pinentry

2. 导入rpm并签名

    # 使用之前导出的公钥
    rpm --import RPM-GPG-KEY-umcloud

确认是否导入成功

    rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n'

生成.rpmmacros

    # vi ~/.rpmmacros
    # %_signature => This will always be gpg
    # %_gpg_path  => Enter full path to .gnupg in your home directory
    # %_gpg_name  => Use the Real Name you used to create your key
    # %_gpbin     => run `which gpg` (without ` marks) to get full path 
    
    %_signature gpg
    %_gpg_path /root/.gnupg
    %_gpg_name umcloud
    %_gpgbin /usr/bin/gpg`)

签名

    # 单个签名
    rpm --addsign git-1.7.7.3-1.el6.x86_64.rpm
    # 多个签名
    rpm --addsign *.rpm

检查是否签名成功

    rpm --checksig (sha1) dsa sha1 md5 gpg OK

导出公钥

    gpg --export -a umcloud > keys/release.asc

然后再生成源

    createrepo -pdo xx/el7/x86_64/ xx/el7/x86_64/

# kvm虚拟机挂载config drive

部分openstack社区提供的虚拟机镜像默认不提供密码登录，只能通过秘钥访问。
如果通过kvm直接启动镜像，需要通过给虚拟机挂载config-drive的方式，将公钥导入到虚拟机 

方式如下
先获得制作config-drive的脚本

```
curl -q https://raw.githubusercontent.com/larsks/virt-utils/master/create-config-drive |\
sed s,/bin/sh,/bin/bash,g > create-config-drive.sh
chmod +x create-config-drive.sh
```

拷贝本机公钥到config-drive
```
./create-config-drive.sh -k ~/.ssh/id_rsa.pub -u vm-config.sh -h cfg01  /var/lib/libvirt/images/vm-config.iso
```

如上，启动虚拟机时，在xml文件中定义如下cdrom即可

``
...
    <disk device="cdrom" type="file">
      <target bus="ide" dev="hda"/>
      <source file="/var/lib/libvirt/images/vm-config.iso"/>
      <driver type="raw" name="qemu"/>
    </disk>
...
```

# linux设置高级路由

如果centos或者ubuntu有多个网口配置同一网段的IP。那么需要为每个口设置默认路由，以保证从该口进入的流量，能够继续从该口出去。

因为IP信息是属于操作系统的，而不是属于网口设备，因此无法控制本机发出的流量走哪个口。

具体配置可以参考以下链接

[centos](https://access.redhat.com/solutions/30564)

[ubuntu](https://www.thomas-krenn.com/en/wiki/Two_Default_Gateways_on_One_System)

# linux提供网关服务，允许其他节点通过本机访问公网

假设内网只有一台机器A能访问外网，其他机器如果有公网访问需求，可以通过A进行转发

步骤如下

```
iptables -t nat -I POSTROUTING 6 -s 192.168.2.0/24 ! -d 192.168.2.0/24 -j MASQUERADE
iptables -I FORWARD 1 -s 192.168.2.0/24 -o enp7s0f0 -j ACCEPT
echo  1 > /proc/sys/net/ipv4/ip_forward
```

如果遇到如下错误

```
iptables: Index of insertion too big.
```

去掉其中的6，即

```
iptables -t nat -I POSTROUTING -s 192.168.2.0/24 ! -d 192.168.2.0/24 -j MASQUERADE
```

在其他节点设置网关或静态路由到机器A，既可访问外网

# ntp配置及检查

`ntpq -p` will display the offsets for each reachable server in milliseconds (`ntpdc -p` uses seconds instead).

`ntpdc -c loopinfo` will display the combined offset in seconds, as seen at the last poll. If supported, `ntpdc -c kerninfo` will display the current remaining correction, just as `ntptime` does.

```
# ntpq -p
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
*169.254.0.2     100.122.36.4     2 u  739 1024  377   33.359   -1.780   3.222
```

> `when`: number of seconds passed since last response

> `poll`: polling interval, in seconds, for source

> `reach`: indicates success/failure to reach source, 377 all attempts successful

> `delay`: indicates the roundtrip time, in milliseconds, to receive a reply

> `offset`: indicates the time difference, in milliseconds, between the client server and source

> `disp/jitter`: indicates the difference, in milliseconds, between two samples

# BPF和eBPF

> netfilter: 当前iptables使用的用于过滤网络的内核模块
> bpf: bpfilter（基于bpf）会替换netfilter供iptables使用。tcpdump，wireshark等也是基于bpf

> ptrace: gdb和strace基于ptrace. ptrace有很多缺点，比如需要改变目标调试进程的父亲，还不允许多个调试者同时分析同一个进程. gdb在调试过程中设置断点会发出SIGSTOP信号，这会让被调试进程进入T（TASK_STOPPED or TASK_TRACED）暂停状态或跟踪状态.
> 动态追踪(dynamic-tracing): dtrace(solaris), systemtap(基于utrace,或者uprobes, uretprobes), perf(kprobes, uprobes), bcc(基于ebpf)

gdb注重交互性，适合离线调试，比如调试core dump
systemtap适合在线分析，对进程影响小

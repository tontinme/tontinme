Table of Contents

[rpm制作源签名](rpm制作源签名)
[linux设置高级路由](linux设置高级路由)

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

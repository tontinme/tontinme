
- [虚拟网络设备介绍](#虚拟网络设备介绍)
-   [tun/tap](##tun/tap)
-   [veth设备](##veth设备)
-   [bridge](##bridge)
-   [bond/team](##bond/team)
-   [macvlan/ipvlan](##macvlan/ipvlan)
-   [macvtap/ipvtap](##macvtap/ipvtap)
-   [ifb](##ifb)

# 虚拟网络设备介绍

参考链接: https://opengers.github.io/openstack/openstack-base-virtual-network-devices-tuntap-veth/

## tun/tap

tun/tap是操作系统内核中的虚拟网络设备，为用户层应用提供数据的接收与传输。实现tun/tap设备的内核模块为tun，该模块提供了一个设备接口/dev/net/tun供用户层程序读写。

tun和tap的区别在于工作的协议栈不同，tap等同于一个以太网设备，用户层程序向tap设备读写的是二层数据包如以太网数据帧，tap设备常用作虚拟机网卡。tun则模拟了网络层设备，操作三层数据比如IP数据包，openvpn使用tun设备在C/S间建立VPN隧道。

如下所示，虚拟机通过tap设备vnet1发送数据给网桥br-eth0, br-eth0另一端是物理机网卡

```
# virsh domiflist 2
Interface  Type       Source     Model       MAC
-------------------------------------------------------
vnet1      bridge     br-eth0    virtio      52:54:00:30:9c:a4

# ps aux |grep qemu | grep docker01 | grep netdev
qemu      2903  0.6 13.1 14098088 8637664 ?    Sl   Oct08 404:47 /usr/libexec/qemu-kvm -name docker01 ... -netdev tap,fd=27,id=hostnet0,...
```

另外，linux上的各种网络应用基本上通过linux socket来和内核空间的网络协议栈通信。qemu-kvm为什么不能也使用socket呢。需要注意的是，qemu-kvm实现的是一台虚拟机，它和宿主机是两台机器，只是都桥接在物理机的软件交换机上。虚拟机发出的网络包属于自身的数据包，因此不应该使用另一台主机的linux socket来通信。

宿主机看到的是虚拟机tap设备上的二层以太网帧，因此宿主机上工作在IP层的iptables无法过滤虚拟机数据包。

## veth设备

veth也是linux实现的虚拟网络设备，veth总是成对出现的，作用是反转数据流方向(比如veth-a收到的数据会从veth-b发出，veth-b收到的数据会从veth-a发出)。一个场景的用途是连接两个network namespace。neutron中，dhcp agent和l3 agent都用到了veth pair。举例如下

虚拟机发出的dhcp请求会被网桥brqba48a3fc-e9转发到接口veth-a，进而到达ns中的veth-b，即能成功的获得dhcp请求

```
#新建veth设备veth-a,veth-b
ip link add veth-a type veth peer name veth-b 

#新建一个network namespace
ip netns add qdhcp-ba48a3fc-e9e8-4ce0-8691-3d35b6cca80a

#将 veth-b 添加到 network namespace
ip link set veth-b netns qdhcp-ba48a3fc-e9e8-4ce0-8691-3d35b6cca80a

#给命名空间中的veth设备 veth-b 设置ip地址， 此IP地址做为同网段虚拟机的dhcp服务器
ip netns exec qdhcp-ba48a3fc-e9e8-4ce0-8691-3d35b6cca80a ip addr add 10.0.0.2/32 dev veth-b
ip netns exec qdhcp-ba48a3fc-e9e8-4ce0-8691-3d35b6cca80a ip link set dev veth-b up

#在nstest命名空间中起一个dnsmasq服务器  
ip netns exec qdhcp-ba48a3fc-e9e8-4ce0-8691-3d35b6cca80a /usr/sbin/dnsmasq --no-hosts --no-resolv --except-interface=lo  --bind-interfaces --interface=veth-b ...

#查看此命令空间中服务监听端口
ip netns exec qdhcp-ba48a3fc-e9e8-4ce0-8691-3d35b6cca80a netstat -tnpl
Active Internet connections (only servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name           
tcp        0      0 10.0.0.2:53          0.0.0.0:*               LISTEN      28795/dnsmasq       

#新建网桥brqba48a3fc-e9
brctl add brqba48a3fc-e9
#将veth-a添加到网桥 brqba48a3fc-e9
brctl addif brqba48a3fc-e9 veth-a

#新建kvm虚拟机过程忽略，查看此虚拟机网卡设备信息 
virsh domiflist testvm
Interface  Type       Source     Model       MAC
-------------------------------------------------------
tap796091c0-07 bridge     brqba48a3fc-e9 virtio      fa:16:3e:85:f8:c
```

## bridge

软件实现的交换机，支持STP，vlan filter, multicast snooping等功能

```
# ip link add br0 type bridge
# ip link set eth0 master br0
# ip link set tap1 master br0
# ip link set tap2 master br0
# ip link set veth1 master br0
```

## bond/team

bond和team都实现了网络接口的聚合。

team比bond多一些高级特性的支持，比如NS/NA(ipv6) link monitoring, load-balancing for LACP（具体可参考https://github.com/jpirko/libteam/wiki/Bonding-vs.-Team-features)。当用到这些特性时，可以使用team替代bond

## macvlan/ipvlan设备

参考文档: https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking/

macvlan指将一个以太网口虚拟成多个，且都拥有不同的mac地址

macvlan有5种类型

* bridge: 同一物理网口上的两个macvlan设备通信时，物理网口充当软件交换机。这种方式是最常见的
* VEPA: 同一物理网口上的两个macvlan设备通信时，需要通过外部的物理交换机进行。这是macvlan的默认模式，但是需要物理交换机支持，比如开启hairpin|vepa|802.1Qbg
* private: 禁止同一物理网口上的两个macvlan设备通信，即使交换机侧支持hairpin mode。
* passthru: 仅允许单独的vm直连物理网口。每个物理网口仅能捆绑一个macvlan接口，好处是可以对vm或容器的mac地址进行更换和独立设置。
* source: 基于mac来过滤流量

```
# ip link add macvlan1 link eth0 type macvlan mode bridge
# ip link add macvlan2 link eth0 type macvlan mode bridge
# ip netns add net1
# ip netns add net2
# ip link set macvlan1 netns net1
# ip link set macvlan2 netns net2
```

ipvlan和macvlan类似，只是各个虚拟网口拥有相同的mac地址

ipvlan有两种模式

* L2 mode: 类似于macvlan的bridge模式，物理网口充当bridge
* L3 mode: 物理网口充当router，支持IP包的路由，具有更好的扩展性

```
# ip netns add ns0
# ip link add name ipvl0 link eth0 type ipvlan mode l2
# ip link set dev ipvl0 netns ns0
```

macvlan/ipvlan都是用来解决不同namespace互访的问题。当使用macvlan bridge模式时，和veth pair + bridge类似，但是架构会简单一些。
当使用macvlan vepa模式时，流量由外部交换机进行处理，性能会比纯软件的linux bridge更好。

二者非常像，社区建议在以下场景使用ipvlan

* 外部交换机/路由器不允许端口和mac一对多的关系
* 网口开启混杂模式后，对该场景导致的性能下降比较在意
* 如果虚拟网口位于不可信任的namespace(比如mac地址可以被伪造或改变)

## macvtap/ipvtap设备

顾名思义，是和tun/tap类似的技术，可以直接被kvm/qemu使用。当使用macvtap/ipvtap时，就不需要额外的linux bridge了，优势和macvlan对比veth pair类似。

```
# ip link add link eth0 name macvtap0 type macvtap
```

## ifb

ifb设备支持汇聚多个源设备的流量，然后进行进一步处理(queue and shape)，而不是丢弃掉

```
# ip link add ifb0 type ifb
# ip link set ifb0 up
# tc qdisc add dev ifb0 root sfq
# tc qdisc add dev eth0 handle ffff: ingress
# tc filter add dev eth0 parent ffff: u32 match u32 0 0 action mirred egress redirect dev ifb0
```

This creates an IFB device named ifb0 and replaces the root qdisc scheduler with SFQ (Stochastic Fairness Queueing), which is a classless queueing scheduler. Then it adds an ingress qdisc scheduler on eth0 and redirects all ingress traffic to ifb0.


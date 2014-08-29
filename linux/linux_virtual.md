------kvm

------lxc

------vagrant

------docker

------geard

------openshift

------cgroup

------difference between docker & openshift

------difference between docker & vagrant

------difference between lxc & docker

------difference between lxc & kvm

docker
=====

**What docker can not do**

1. Docker是基于linux64的，无法在32位环境下使用

2. LXC是基于cgroup等linux kernel功能的，因此container的guest系统需要是linux base的

3. 隔离性相比kvm之类的虚拟化方案还是有些欠缺，所以container公用一部分的运行库

4. 网络管理相对简单，主要是基于namespace隔离

5. cgroup的cpu和cpuse提供的cpu功能相比kvm等的虚拟化方案难以衡量（所以dotcloud主要是按照内存收费）

6. docker对disk的管理比较有限

7. container随着用户进程的停止而销毁，container中的log等数据不易收集

docker核心解决的问题是利用LXC来实现类似vm的功能，从而利用更加节省的硬件资源提供给用户更多的计算资源。
docker主要解决虚拟化的四个问题：

* 隔离性--每个用户实例之间相互隔离，互不影响。硬件虚拟化给出的方法是vm，lxc给出的是container，更细一点
是linux namespace。

* 可配额/可度量--每个用户实例可以按需提供其计算资源，所使用的资源可以被计量。硬件虚拟化因为虚拟了cpu，memory
可以方便实现，lxc则主要利用cgroups来控制资源

* 移动性--用户的实例可以很方便的复制，移动和重建。硬件虚拟化提供snapshot和image来实现，docker主要利用
AUFS实现

* 安全性--硬件虚拟化的方法因为虚拟化的水平较高，用户进程都在kvm等虚拟容器中翻译运行。然而对于lxc，用户的进程
是lxc-start进程的子进程，只是在Kernel的namespace中隔离实现的，因此需要一些kernel的patch来保证用户的运行环境
不会受到来自host主机的恶意入侵，dotcloud主要是利用kernel grsec patch来解决的

**What can we do with Docker**

*Sandbox*

  作为sandbox大概是docker最基本的想法了-轻量级的隔离机制，快速重建和销毁，占用资源少。用于构建多平台image的packer
	和同一作者的vagrant已经在这方面有所尝试了

*PaaS*

dotcloud, heroku以及cloudfoundry都试图通过container来隔离提供给用户的runtime和service，dotcloud采用docker，heroku
采用Lxc,cloudfoundry采用自己开发的基于cgroup的warden。基于轻量级的隔离机制提供给用户PaaS服务是比较常见的做法-
PaaS提供给用户的不是OS而是runtime+service，因此OS级别的隔离机制向用户屏蔽的细节已经足够。

PaaS号称的platform一直以来都被当作一组多语言的runtime和一组常用的middleware，提供这两样东西即被认为是一个满足需求的
PaaS。然而docker确实从另一个角度（类似IaaS+orchestration tools）实现了用户环境的控制和管理，然而又基于轻量级的lxc
机制，确实是一个了不起的尝试

*Linux namespace*

c所实现的隔离性主要是来自kernel的namespace，其中pid, net, ipc, mnt, uts等namespace将container的进程，网络，消息，
文件系统和hostname隔离开

*pid namespace*

之前提到用户的进程是lxc-start进程的子进程，不同用户的进程就是通过pid namespace隔离开的，且不同namespace中
可以有相同的pid。具有以下特征：

a. 每个namespace中的pid是有自己的pid=1的进程
b. 每个namespace中的进程只能影响自己的同一个namespace或子namespace中的进程
c. 因为/proc包含正在运行的进程，因此在container中的pseudo-filesystem的/proc目录智能看到自己namespace的进程
d. 因为namespace允许嵌套，父namespace可以影响子namespace的进程，所以子namespace的进程可以在父namespace中看到，
但是具有不同的pid

正是具有以上的特征，所有的LXC进程在docker中的父进程为docker进程，每个lxc进程具有不同的namespace。同时由于允许嵌套，
因此可以很方便的实现lxc in lxc

*net namespace*

网络隔离是通过net namespace实现的，每个net namespace有独立的network devices, ip address, ip routing tables, /proc/net
目录。这样每个container的网络就能隔离开来。LXC在此基础上有五种网络类型，docker默认采用veth的方式将container的虚拟网卡
同host上的一个docker bridge连接在一起。

*ipc namespace*

container中进程交互还是采用linux中常见的进程交互方法(interprocess communication - IPC), 包括常见的信号量，消息队列和
共享内存。然而同vm不同，container的进程交互实际上还是host上具有相同pid namespace中的进程间交互，因此需要在IPC资源
申请时加入namespace信息 - 每个ipc资源有一个唯一的32bit ID

*mnt namespace*

类似chroot, 将一个进程放到一个特定的目录执行。mnt namespace允许不同namespace的进程看到的文件结构不同，这样每个namespace
中的进程所看到的文件目录就被隔离开了。同chroot不同，每个namespace中的container在/proc/mounts的信息只包含在所在
namespace的mount point.

*uts namespace*

UTS(Unix Time-sharing System) namespace允许每个container拥有独立的hostname和domain name，使其在网络上可以被视作一个独立的
节点而非Host上的一个进程

*User namespace*

每个container可以有不同的user和group id，也就是说可以以container内部的用户执行container内部的程序，而不是使用Host上的用户
有了以上6种namespace从进程，网络，ipc，文件系统，uts和用户角度的隔离，一个container对外就可以展现出一个独立计算机的能力。
并且不同container从OS层面实现了隔离。然而不同namespace之间资源还是相互竞争的，仍然需要类似ulimit来管理每个container所能使用
的资源 - lxc使用的是cgroup

**Docker Disk/network quota**

虽然cgroup提供IOPS之类的限制机制，但是从限制用户能使用的磁盘大小和网络带宽上还是非常有限的

Disk/Network的quota现在有两种思路：

* 通过docker run -v 命令将外部存储mount到container的目录下，quota从Host方向限制，在device mapper driver中采用更实际的device，因此
更好控制
* 通过使用disk quota来限制AUFS的可操作文件大小。类似cloud foundray warden的方法，维护一个UID池，每次创建container都从中取一个user 
name，在container里和Host上用这个username来创建用户，在Host上用setquota限制该username的UID的disk，网络上由于docker采用veth的
方式，可以采用tc来控制host上的veth设备

Cgroup(Control Groups)
=====

cgroup实现了对资源的配额和度量。在/cgroup下新建一个文件夹即可新建一个group，在此文件夹中新建task文件，并将pid写入该文件，即可实现
对该task的资源控制。具体的资源选项，可以在该文件夹中新建子subsystem，{子系统前缀}.{资源项}是典型的配置方法，如memory.usage_in_bytes
就定义了该group在subsystem memory中的一个内存控制选项。另外，cgroups中的subsystem可以随意组合，一个subsystem可以在不同的group中，
也可以一个group包含多个subsystem

我们主要关心cgroup可以限制哪些资源，即有哪些subsystem是我们关心的

* cpu - 在cgroup中，并不能像硬件虚拟化方案一样定义cpu能力，但是能够定义cpu轮转的优先级，因此具有较高cpu优先级的进程会更可能得到cpu
运算。通过将参数写入cpu.shares，即可定义cgroup的cpu优先级-这里是一个相对权重，而非绝对值。
* cpusets - cpusets定义了有几个cpu可以被这个group使用，或者哪几个cpu可以供这个group使用。某些场景下，单cpu绑定可以防止多核间缓存
切换，提高效率
* cpuacct - 自动生成cgroup中任务所使用的cpu的报告
* memory - 内存相关的限制，并自动生成由那些任务使用的内存资源的报告
* blkio - block io 相关的统计限制，byte/operation统计和限制(IOPS等)，读写速度限制等，但是这里统计的都是同步IO
* devices - 可通过devices允许或拒绝cgroup中的任务访问设备
* freezer - 可挂起或恢复cgroup中的任务
* net_cls - 使用等级识别符(classid)标记网络数据包，可允许Linux流量控制程序(tc)识别从具体cgroup中生成的数据包

LXC
=====

借助于namespace的隔离机制和cgroup限额功能，LXC提供了一套统一的API和工具来建立和管理container，lxc利用了kernel的如下features:

* Kernel namespaces(ipc, uts, mount, pid, network and user)
* Apparmor and SELinux profiles
* Seccomp policies
* Chroots(using pivot_root)
* Kernel capabilities
* Control groups(cgroups)

LXC向用户屏蔽了以上kernel接口的细节，提供了如下组件大大简化了用户的开发和使用工作:

* the liblxc library
* Several language binding(python3, lua and Go)
* A set of standard tools to control the containers
* Container templates

LXC旨在提供一个共享kernel的OS级虚拟化方法，在执行时不用重复加载kernel，且container的kernel与host共享，因此可以大大加快container的
启动过程，并显著减少内存消耗。在实际测试中，基于lxc的虚拟化方法的IO和CPU性能几乎接近baremetal的性能
[http://marceloneves.org/papers/pdp2013-containers.pdf (性能测试)]。大多数数据相比Xen具有优势。当然对于KVM这种也是通过Kernel
进行隔离的方式，性能优势或许不是那么明显，主要还是内存消耗和启动时间上的差异。在(http://www.spinics.net/lists/linux-containers/msg25750.html)
中提到了利用iozone进行disk io吞吐量测试，Kvm反而比lxc要快，而笔者在device mapping driver下重现同样case的实验中也确实得到如此
结论，(http://article.sciencepublishinggroup.com/pdf/10.11648.j.ajnc.20130204.11.pdf)该文献从网络虚拟化中虚拟路由的场景（个人理解
是网络IO和CPU的角度）比较了kvm和lxc，得到结论是kvm在性能和隔离性的平衡上比lxc更优秀 - kvm在吞吐量上略差于lxc，但cpu的隔离可
管理项比lxc更明确

关于cpu, diskIO,networkIO和memory在kvm和lxc中的比较还是需要更多的实验才能得出可信服的结论

AUFS
=====

docker对container的使用基本是建立在lxc基础上的，然而lxc存在的问题是难以移动 - 难以通过标准化的模板制作，重建，复制和移动container。
docker利用AUFS来实现对container的快速更新 - 在docker0.7中引入了storage driver，支持aufs， vfs， device mapper，也为btrfs以及
zfs引入提供了可能。但除了aufs都未经过dotcloud的线上使用

auFS(Another Union FS)是一种Union FS，简单来说就是支持将不同目录挂载到同一个虚拟文件系统下(unitte several directories into a single
filesystem)的文件系统，更进一步的，aufs支持为每一个成员目录(AKA branch)设定'readonly','readwrite'和'whiteout-able'权限，同时AUFS
里有一个分层概念，对readonly权限的branch可以逻辑上修改。通常Union FS有两个用途，一方面可以实现不借助LVM，RAID将多个disk挂在一个
目录下，另一个更常用的就是将一个readonly的branch和一个writeable的branch联合在一起.

典型的Linux启动到运行需要两个FS - bootfs + rootfs（从功能角度而非文件系统角度）

bootfs主要包含bootloader和kernel，bootloader主要是引导加载kernel，当boot成功后kernel被加载到内存后bootfs就被umount了。rootfs包含的就是典型的
linux系统中的/dev, /proc, /bin, /etc/等标准目录和文件

由此可见对于不同的linux发行版，bootfs基本是一致的，rootfs会有差别，因此不同的linux发行版可以公用bootfs

典型的linux启动后，首先将rootfs置为readonly，进行一系列检查，然后将其切换为'readwrite'供用户使用。在docker中，起初也是将rootfs以readonly
方式加载并检查，然后接下来利用union mount将一个readwrite的文件系统挂载在readonly的rootfs之上，并且允许再次将下层的file system设定
为readonly并且向上叠加，这样一组readonly和一个writeable的结构构成一个container的运行目录，每一个被称作一个layer

	writable		| Container
	add Apache	| Image
	add emacs		| Image	    | <-- parent Image
	Debian		| Base image
	lxc,aufs/btrfs	| kernel

得益于AUFS的特性，每一个对readonly层文件/目录的修改都只会存在于上层的writeable层中。这样由于不存在竞争，多个container可以共享readonly的layer。
所以docker将readonly层叫做image - 对于container而言整个rootfs都是read-write的，但事实上所有的修改都在最上层的writeable层中，image不保存
用户状态，可以用于模板，复制和重建。

上层的Image依赖下层的image，因此docker把下层的image称作父Image，没有父image的image叫做base image。

因此想要从一个image启动一个container，docker会先加载其父image直到base image，用户的进程运行在writeable的layer中。所有parent image中的数据信息
以及ID，网络和lxc管理的资源限制等具体container的配置，构成一个docker概念上的container

由此可见，采用AUFS作为docker的container文件系统，能提供如下好处：

* 节省存储空间 - 多个container可以共享base image存储
* 快速部署 - 如果要部署多个container，base image可以避免多次拷贝
* 内存更省 - 因为多个container共享base image，以及OS的disk缓存机制，多个container中的进程命中缓存内容的几率大大增加
* 升级更方便 - 相比于copy-on-write类型的FS，base-image也是可以挂载为writeable的，可以通过更新base-image一次性更新其之上的container。
* 允许在不更改base-image的同时修改其目录中的文件 - 所有写操作都发生在其最上层的writeable层，这样可以大大增加base-image层能共享的文件内容

以上5条中1-3可以通过copy-on-write的FS实现，4可以利用其他的union mount方式实现，5只有AUFS实现的很好。因此docker一开始就选择建立在AUFS之上

由于AUFS并不会进入linux主干（According to Christoph Hellwig, linux reject all union-type filessytems but UnionMount）,同时要求kernel 3.0以上（
docker推荐3.8以上），因此在redhat帮助下在docker0.7版本中实现了driver机制，AUFS只是其中的一个driver，在rhel中采用的是Device Mapper的方式
实现的container文件系统

GRSEC
=====

grsec是linux kernel安全相关的patch，用于保护host防止非法入侵。它不是docker的一部分。grsec从四方面保护进程不被非法入侵：

* 随机地址空间 - 进程的堆区地址是随机的
* 用只读的memory management unit来管理进程流程，堆区和栈区内存只包含数据结构/函数/返回地址和数据，是non-executeable
* 审计和log可疑活动
* 编译期的防护

安全永远是相对的，这些方法只是告诉我们可以从这些角度考虑container类型的安全问题

Device mapper driver
=====

简而言之，docker的driver要利用snapshot机制，起初的fs是一个空的ext4目录，然后写入每个layer。每次创建image其实就是对其parent/base image进行
snapshot，然后在此snapshot上的操作记录都会被记录到fs的metadata中。docker commit将diff信息在parent/base image上执行一遍，这样创建出来的
image就可以同当前container的运行环境分离开独立保存了。

(https://groups.google.com/forum/#!topic/docker-dev/KcCT0bACksY) (http://blog.docker.com/2013/11/docker-0-7-docker-now-runs-on-any-linux-distribution/)

The way it works is that we set up a device-mapper thin provisioning pool with a single base device containing an empty ext4 filesystem.
Then each time we create an image we take a snapshot of the parent image (or the base image) and manually apply the AUFS layer to
this. Similarly we create snapshots of images when we create containers and mount these as the container filesystem.

*docker diff* -  is implemented by just scanning the container filesystem and the parent image filesystem, looking at the metadata for changes.
Theoretically this can be fooled if you do in-place editing of a file (not changing the size) and reset the mtime/ctime, but in
practice I think this will be good enough.

*docker commit* - uses the above diff command to get a list of changed files which are used to construct a tarball with files and
AUFS whiteouts (for deletes). This means you can commit containers to images, run new containers based on the image, etc.
You should be able to push them to the index too (although I've not tested this yet).

Docker looks for a *docker-pool* device-mapper device (i.e. /dev/mapper/docker-pool) when it starts up, but if none exists it
automatically creates two sparse files (100GB for the data and 2GB for the metadata) and loopback mount these and sets these up
as the block devices for docker-pool, with a 10GB ext4 fs as the base image.

This means that there is no need for manual setup of block devices, and that generally there should be no need to pre-allocate
large amounts of space (the sparse files are small, and we things up so that discards are passed through all the way back
to the sparse loopbacks, so deletes in a container should fully reclaim space.

目前已知的问题是删除的image的block文件没有被删除，看起来是kernel issue

difference between docker & openshift
=====

The primary difference is that Docker as a project is focused on the runtime container only, whereas openshift(as a system) includes both
the runtime container as well as the REST API, coordination, and web interfaces to deploy and manage individual containers.

Comparing just the runtime containers, OpenShift and Docker both use kernel isolation features to keep tenant processes separate. For docker,
that is primarily through LXC and for OpenShift that is largely through SELinux and Multiple Category Security(MCS). Both use cgroups
to limit the CPU, MEM and IO of tenants. Upstream OpenShift is looking at LXC to reduce long term effort.

Docker uses AUFS for advanced disk and file copy-on-write sharing, OpenShift neither requires nor is incompatible with such a system.

Inside the container, OpenShift models units of functionality(web service, dbs) via "cartridges", which are a set of shell script hooks that
are called when the system is invoked. A cartridge is similar to a docker image.

As of Apirl 2014 OpenShift has launched geard, a project which will form the basis of the next generation of OpenShift by combining Docker 
and systemd to host Docker container. This will replace the current OpenShift node model.

difference between docker & vagrant
=====

Vagrant, is best described as a VM manager. It designed to run on top of almost any VM tools - VirtualBox, VMWare, AWS, etc. However, 
default support is only included for VirtualBox. However, Vagrant is still a virtual machine, albeit one with more powerful features 
than the bog-standard VM tools out there. for instance you can integrate Vagrant with CM tools such as puppet and chef to provision
your own VM setups and configs.

Docker is really an extension of LXC, which is itself a sort of supercharged linux chroot.

Vagrant still creates VM, although these are still lighter than the full-fat VM's created by VM emulators. Vagrant provides a reproducible way
to generate fully virtualized machines using VirtualBox, Vmware or AWS as providers.

In some scenario, Vagrant is used to create a base VM, then when you need to create different configs that all utilize this base VM, use 
Docker to provision and create different lightweight versions.

If you main need is isolation and you require to quickly create several different VE images, then definitely use Docker. Docker is also ideal
for environments in which you are testing several short-lived images, such as when you need different scenarios for testing or debuging 
software. Vagrant is better when you require full VM's and full isolation for these VM's.

A Summary of the difference between Docker and Vagrant

	Feature							  Docker			  Vagrant
	Virtualization Type					  VE		  		  VM
	Guaranteed Resources at hardware level		  No		  		  Yes
	Supported OS Platforms				  linux only  		  linux,Unix,Windows
	Startup time for created machine			  A few sec	  		  A few min
	Isolation level for created virtual system	  Partial			  full
	Weight of the created virtual system		  Very lightweight	  Heavy, but still better than full VM
	Other Advantages					  Quick, Easy to learn	  Integration with CM tools

difference between lxc & docker
=====

Docker is not a replacement of lxc. lxc refers to capabilities of the linux kernel(sepcifically 
namespaces and control groups) which allow sandboxing processes from one another, and controlling
their resource allocations.

On top of this low-level foundation of kernel features, Docker offers a high-level tool with several
powerful functionlities.

1. Portable deployment across machines. Docker defines a format for bundling an application and all its
dependencies into a single object which can be transferred to any docker-enabled machine. and executed
there with the guarantee that the execution environment exposed to the application will be the same.

    * Lxc implements process sandboxing, which is an important pre-requisite for portable deployment, but that 
alone is not enough for portable deployment.

2. Application-centric. Docker is optimized for the deployment of applications, as opposed to machines. 
This is reflected in is API, user interface, design philosophy and documention. By contrast, the lxc helper
scripts focus on containers as lightweight machines - basically servers that boot faster and need less
ram.

3. Automatic build. Docker includes a tool for developers to automatically assemable a container, inspecting 
the diff between versions, committing new versions, rolling back etc.

4. Components re-use. Any container can be used as an "base image" to create more specialized components. This 
can be done manually or as part of an automated build.

5. Sharing. Docker has access to a public registry where thousands of people have uploaded useful containers.

6. Tool ecosystem. Docker defines an API for automating and customing the creation and deployment of containers.
There are a huge number of tools integrating with docker to extend its capabilities.

List of Docker's technical features.

a. Filesystem isolation: each process container runs in a completely seperate root filesystem

    * Provided with plain LXC.

b. Resource isolation: ...

    * Provided with plain LXC

c. Network isolation: ...

    * Provided with plain LXC

d. Copy-on-write: root filesystems are created using copy-on-writed, which make deployment extremely fast, memory-cheap
and disk-cheap.

    * This is provided by AUFS, a union filesystem that Docker depends on. you could set up AUFS yourself manually with 
LXC, but Docker use it as a standard.

e. Logging: the standard streams(stdin/stdout/stderr) of each process container is collected and logged for real-time 
or batch retrieval.

    * Docker provided this.

f. Change management: changes to a container's filesystem can be committed into a new image and re-used to create more
container. No templating or manual configuration required.

    * "Templating or manual configuration" is a reference to LXC. where you would need to learn about both of these things.
Docker allows you to treat containers in the way that you're used to treating virtual machines, without learing 
about LXC configuration.

g. Interactive shell: docker can allocate a pseudo-tty and attch to the standard input of any container, for example to 
run a throwaway interactive shell.

    * LXC already provides this.

difference between lxc & kvm
=====

The main difference between the KVM virtualization and Linux Containers is that
virtual machines require a separate kernel instance to run on, while containers
can be deployed from the host operating system. This significantly reduces the 
complexity of container creation and maintenance. Also, the reduced overhead lets
you create a large number of containers with faster startup and shutdown speeds.
Both Linux Containers and KVM virtualization have certain advantages and drawbacks
that influence the use cases in which these technologies are typically applied:

**KVM virtualization**

KVM virtualization lets you boot full operating systems of different kinds, even non-Linux systems.
However, a complex setup is sometimes needed. Virtual machines are resource-intensive 
so you can run only a limited number of them on your host machine.

Running separate kernel instances generally means better separation and security. If one of
the kernels terminates unexpectedly, it does not disable the whole system. On the other hand,
this isolation makes it harder for virtual machines to communicate with the rest of the system,
and therefore several interpretation mechanisms must be used.

Guest virtual machine is isolated from host changes, which lets you run different versions
of the same application on the host and virtual machine. KVM also provides many useful
features such as live migration. For more information on these capabilities, see
Red Hat Enterprise Linux 7 Virtualization Deployment and Administration Guide.

**Linux Containers**

The current version of Linux Containers is designed primarily to support isolation of one
or more applications, with plans to implement full OS containers in the near future.
You can create or destroy containers very easily and they are convenient to maintain.

System-wide changes are visible in each container. For example, if you upgrade an
application on the host machine, this change will apply to all sandboxes that run instances of this application.

Since containers are lightweight, a large number of them can run simultaneously on a
host machine. The theoretical maximum is 6000 containers and 12,000 bind mounts of
root file system directories. Also, containers are faster to create and have low startup times.

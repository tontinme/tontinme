Install Docker CoreOS Vagrant on Mac OSX
=====

1. 安装vagrant和virtualBox

    http://www.vagrantup.com/downloads.html (version >= 1.6.3)
    VirtualBox (version >=4.3.10)

2. 获得coreOS的vagrantfile

    git clone https://github.com/coreos/coreos-vagrant.git
    cd coreos-vagrant

3. 启动前修改配置

    cp user-data.sample user-data
    #cloud-config file
    cp config.rb.sample config.rb
    #config.rb包含一些vagrant的环境设置和要启动的cluster中CoreOS的数量

4. 启动CoreOS

    vagrant up
    vagrant status
    #查看机器的运行状态
    vagrant ssh core-01 -- -A

Intro: etcd
=====

A high-available key value store for shared configuration and service discovery. Next to that it can be
used for service discovery, or basically for any other distributed key/value based process that applies 
to your situation. etcd is inspired by Apache ZooKeeper and doozer, with a focus on being:
    
* simple: curl'able user facing API(HTTP+JSON)
* Secure: optional SSL client cert authentication
* Fast: benchmarked 1000s of writes/s per instance
* Reliable: properly distributed using Raft

Etcd is written in Go and uses the Raft consensus algorithm to manage a highly-available replicated log

etcdctl is a simple command line client. or feel free to just use curl.

**1.Running etcd**
    
    ./bin/etcd -data-dir machine0 -name machine0    #This will bring up etcd listening
    on default ports(4001 for client communication and 7001 for server-to-server communication)
    The '-data-dir machine0' argument tells etcd to write machine configuration, logs and 
    snapshots to the ./machine0/ directory. The '-name machine0' tell the rest of the cluster
    that this machine is named machine0

**2.Getting the etcd version**

    curl -L 'http://127.0.0.1:4001/version'

**3.Key Space Operations**

Some Example:
    
    #set value
    curl -L 'http://127.0.0.1:4001/v2/keys/msg' -XPUT -d value="cool cool cool"
    #get value
    curl -L 'http://127.0.0.1:4001/v2/keys/msg'
    #wait for a change
    curl -L 'http://127.0.0.1:4001/v2/keys/msg?wait=true'
    #automically creating in-order keys
    curl -L 'http://127.0.0.1:4001/v2/keys/queue' -XPOST -d value="job1"
    curl -L 'http://127.0.0.1:4001/v2/keys/queue' -XPOST -d value="job2"
    #automic compare-and-swap
    curl -L 'http://127.0.0.1:4001/v2/keys/foo?prevValue=two' -XPUT -d value=three
    #creating directories
    curl -L 'http://127.0.0.1:4001/v2/keys/dir' -XPUT -d dir=true
    #creating a hidden node
    curl -L 'http://127.0.0.1:4001/v2/keys/_msg' -XPUT -d value="create a hidden kv pair or dir by add a _ prefix."
    #setting a key fro a file
    echo -ne "Hello\tWorld\n" > a.file
    curl -L 'http://127.0.0.1:4001/v2/keys/afile' -XPUT --data-urlencode value@a.file
    #read from the master
    curl -L 'http://127.0.0.1:4001/v2/keys/msg?consistent=true'
    #read linearization
    curl -L 'http://127.0.0.1:4001/v2/keys/msg?quorum=true'

**4.Statistics**

Some Example:

    curl -L 'http://127.0.0.1:4001/v2/stats/leader'
    curl -L 'http://127.0.0.1:4001/v2/stats/self'
    curl -L 'http://127.0.0.1:4001/v2/stats/store'

**5.Cluster Config**

Some Example:
    
    #set config
    curl -L 'http://127.0.0.1:7001/v2/admin/config' -XPUT -d value='{"activeSize":3, "removeDelay":1800,"syncInterval":5}'
    curl -L 'http://127.0.0.1:7001/v2/admin/machines'
    #remove machine
    curl -L 'http://127.0.0.1:7001/v2/admin/machines/peer2'
    curl -XDELETE -L 'http://127.0.0.1:7001/v2/admin/machines/peer2'

Intro: confd
=====

confd is a configuration management tool built on top of etcd. Confd can watch certain keys in etcd, and updated the related
configuration files as soon as the key changes. After that, confd can reload or restart applications related to the updated 
configuration files. This allow you to automate configuration files to all the servers in your cluster, and make sure all the
services are always looking for the latest configuration.

Intro: fleet
=====

fleet is a layer on top of systemd, the well-known init system. fleet basically lets you manage your service on any server in
your cluster transparently, and give you some convenient tools to inspect the state of your services.

CoreOS vs Project Atomic
=====

Deployment
-----

**CoreOS**

CoreOS share a key-value pair system called etcd that is clustered between all of the nodes. You can add data to etcd from any
node and any other node can read that data. 

You can use the standard *docker pull* and *docker run* commands to launch containers. Or writing systemd unit files and submitting
them to the cluster via fleetctl. It's a good idea to pull the containers ahead of time to save time when containers are launched 
on other nodes.

When a node fails or needs to be rebooted for an update. The containers runing on a host that is going offline will be migrated to 
another node in the cluster. If you haven't pulled the container image down to each machine in the cluster, you'll be waiting a bit 
before the container comes up on another node.

**Project Atomic**

There are two deployment methods available for Project Atomic: QEMU(KVM) and VirtrualBox.

Much like CoreOS, you can deploy containers using the standard docker commands. Also, the project centers around a new piece of software
 called geard. It allows you to link different containers together and work with them as a unit.

Management
-----

**CoreOS**

Thers's very little to manage with CoreOS. Updates are handled using an A/B system where updated are staged and reboots are automated. 
Rollbacks can be done during bootup if an update wend badly. Multiple update strategies are available within CoreOS.

CoreOS provides quick access to many tools using a *Fedora container called toolbox* started by *systemd-nspawn*. It's a great way to dig
through errors or test our some scripts.

It offers a handy management system called *fleet*. A client, fleetctl, allows you to list all of your running containers(called units, 
due to the systemd units files) as well as all of your nodes.

**Project Atomic**

Both /usr and /var are mounted read only don't even try using yum. You will update these systems using a new method: *rpm-ostree*.

The idea behind rpm-ostree is similiar to tossing your OS into a git repository. Running rpm-ostree causes the tool to sync down a tree 
of data that you'd normally get by running yum or rpm.

There is a helpful GUI called *cockpit* that gives you a great status readout on all of your connected servers.

Atomic's base OS is very close to Fedora 20.

Security
-----

**CoreOS**

Authentication in CoreOS is mainly done with public ssh keys for now. I couldn't find any options for using LDAP, Kerberos, or other centralized 
authentication mechanisms.

You'll also find that systems is built without SELinux, AppArmor and audit support. Seccomp is included. IMA is also included.

**Project Atomic**

Security seems to be much more of a focus within Project Atomic. SELinux is enabled by default and you'll find IMA, audit and libwrap available from
 systemd. Running containers have SELinux contexts applied and SVirt is used to enforce boundaries between containers. Cockpit and SELinux don't get
 along well yet and you'll will be forced run dreaded setenforce 0 if you want to use cockpit.

Install Debugging Tools
-----

You can use common debugging tools like tcpdump or strace with Toolbox. Using the filesystem of a specified docker container Toolbox will launch a 
container with full system privileges including access to system PIDs, network interfaces and other global information. Inside the toolbox, the 
machine's filesystem is mounted to /media/root.

**QuickDebugging**

By default, Toolbox uses the stock Fedora docker container. To start using it, simply run:

    /usr/bin/toolbox

For example, if you'd like to use tcpdump:

    [root@srv-3qy0p ~]# yum install tcpdump
    [root@srv-3qy0p ~]# tcpdump -i ens3
    tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
    listening on ens3, link-type EN10MB (Ethernet), capture size 65535 bytes

**Specify a Custom Docker Image**

Create a .toolbox in the user's home folder to use a specific docker image:
    
    $ cat .toolboxrc
    TOOLBOX_DOCKER_IMAGE=index.example.com/debug
    TOOLBOX_USER=root
    $ /usr/bin/toolbox
    Pulling repository index.example.com/debug
    ...

**SSH Directly Into a Toolbox**

Advanced users can SSH directly into a toolbox by setting up an /etc/passwd entry:

    useradd bob -m -p '*' -s /usr/bin/toolbox

To test, SSH as bob:

    ssh bob@hostname.example.com
    [root@srv-3qy0p ~]# yum install emacs
    [root@srv-3qy0p ~]# emacs /media/root/etc/systemd/system/docker.service



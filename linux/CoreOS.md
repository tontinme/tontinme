Install Docker CoreOS Vagrant on Mac OSX
-----

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
-----
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
-----

confd is a configuration management tool built on top of etcd. Confd can watch certain keys in etcd, and updated the related
configuration files as soon as the key changes. After that, confd can reload or restart applications related to the updated 
configuration files. This allow you to automate configuration files to all the servers in your cluster, and make sure all the
services are always looking for the latest configuration.

Intro: fleet
-----

fleet is a layer on top of systemd, the well-known init system. fleet basically lets you manage your service on any server in
your cluster transparently, and give you some convenient tools to inspect the state of your services.

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

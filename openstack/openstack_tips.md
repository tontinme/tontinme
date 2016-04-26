## regions, cells, host aggregates, availability zones, domain

### REGIONS:

是openstack级别的概念。REGIONS之间都是独立的，一般通过地理位置区分。大部分endpoint都是独立的（除了keystone和horizon）。类似于阿里云让你选择青岛还是杭州。region之间没有任何关系，只是通过keystone用来认证，通过horizon用来管理。

### CELLS:

是openstack级别的概念。是为了解决扩展性和规模瓶颈而提出的。每个cell有自己的DB和MQ（但DB，MQ中的内容和作用都不一样）。在每一级cell中都有nova-cell服务，目的是为了让openstack自身就带有高扩展性，避免运维人员去维护MQ集群，DB集群的操作。当请求发送过来时，nova-cells服务会把请求发送给一个子cell。比如用户请求是发送给nova-api的，我们有一个parent cell, 上面安装了DB, AMQP broker, nova-cells, nova-api。另外我们有两个子cell，每个cell都安装了独立的DB, AMQP broker，nova-cells, nova-scheduler, nova-network, nova-compute。当我们向parent cell发送请求后，parent cell会把请求发送给子cell，由子cell去做实际的请求。这相当于每个cell都相互独立，但共享一个nova-api(这个nova-api安装在最顶层)。

### HOST AGGREGATES

是compute node级别的概念。由scheduler选择客户的vm放在哪个compute node上。至于哪个compute node属于哪个host aggregates由管理员根据硬件设施指定（比如CPU，SSD，内存）。客户在建立虚拟机的时候不会看到host aggregates这种东西。比如我在一个availability zone中配置两个host aggregates，一个高配，一个低配，客户只能选择到availability zone, 但scheduler可以根据实际情况意识到应该将vm建在哪里。也就是说，host aggregates注重的是质量。建立host aggregates时可以指定属性（比如,设置SSD=true）。这样nova boot时，可以添加参数SSD=true，就会选择对应host aggregates上面的compute。

### AVAILABILITY ZONE

是compute级别的概念。由客户自己选择放在哪里（比如指定机柜），定义是由管理员定义的。availability zone主要体现在availability上，比如我有两个机柜，由不同电源供电，一个坏了不影响另外一个。那么我就可以建立两个availability zone。客户建立虚拟机时也就知道availability zone是相互独立的，不会同时宕机。也就是说，availability zone注重的是可用性。

### domain

是openstack级别的概念。用于更好的管理用户和租户。如果没有domain这个概念，那么一个admin role就是整个openstack的admin。如果有了domain，那么我只要把某个用户设置为某个domain admin role，这样他只能管理自己的domain，但不能管理其他domain。cloud是最大级别，cloud下面是domain。domain中可以有tenant, user。一个tenant, user只能属于一个domain，每个domain都有domain admin帐号。domain由cloud admin创建，cloud admin可以指派domain admin。

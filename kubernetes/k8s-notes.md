ToC

[localpv]
[CSI]
[resource limit]
[kube-scheduler]


# localpv

手动删除localpv流程：
1. 删除使用这个pv的pod
2. 从宿主机移除本地磁盘（比如umount）
3. 删除pvc
4. 删除pv


# CSI

可以看到，相比于 FlexVolume，CSI 的设计思想，把插件的职责从“两阶段处理”，扩展成了 Provision、Attach 和 Mount 三个阶段。其中，Provision 等价于“创建磁盘”，Attach 等价于“挂载磁盘到虚拟机”，Mount 等价于“将该磁盘格式化后，挂载在 Volume 的宿主机目录上”。

# resource limit & request

而如果你指定了 limits.cpu=500m 之后，则相当于将 Cgroups 的 cpu.cfs_quota_us 的值设置为 (500/1000)*100ms，而 cpu.cfs_period_us 的值始终是 100ms。
更确切地说，当你指定了 requests.cpu=250m 之后，相当于将 Cgroups 的 cpu.shares 的值设置为 (250/1000)*1024。

# kube-scheduler

kube-scheduler：pod调度串行（防止打分互相干扰），节点predicate和priortity并行，提高过滤node的性能


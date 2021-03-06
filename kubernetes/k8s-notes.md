ToC

- [localpv](#localpv)
- [CSI](#csi)
- [resource limit](#resource-limit)
- [kube-scheduler](#kube-scheduler)
- [kubectl attach vs kubectl exec](#kubectl-attach-vs-kubectl-exec)
- [](#)
- [](#)


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

# kubectl attach vs kubectl exec 

It can attach to the main process run by the container, which is not always bash.
As opposed to exec, which allows you to execute any process within the container (often: bash)

> exec: any one you want to create
> attach: the one currently running (no choice)

In addition to interactive execution of commands, you can now also attach to any running process. Like kubectl logs, you’ll get stderr and stdout data, but with attach, you’ll also be able to send stdin from your terminal to the program.
Awesome for interactive debugging, or even just sending ctrl-c to a misbehaving application.

kubeclt attach用法介绍:

https://github.com/kubernetes/kubernetes/issues/23335

```
$> kubectl attach redis -i

$ kubectl attach --help
Attach to a process that is already running inside an existing container.

Usage:
  kubectl attach POD -c CONTAINER [flags]

Examples:
# Get output from running pod 123456-7890, using the first container by default
$ kubectl attach 123456-7890

# Get output from ruby-container from pod 123456-7890
$ kubectl attach 123456-7890 -c ruby-container

# Switch to raw terminal mode, sends stdin to 'bash' in ruby-container from pod 123456-7890
# and sends stdout/stderr from 'bash' back to the client
$ kubectl attach 123456-7890 -c ruby-container -i -t
```





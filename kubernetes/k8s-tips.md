---
# introduce

## 1. 概念介绍

* `replication controller(rc)`: RS支持新的基于集合（ set-based）的选择器，而RC只支持基于相等（ equality-based ）的选择器

* `replica set(rs)`: rs的selector选择器多了两种除了相等和非相等之外的筛选模式，使得筛选和管理pod更为灵活

* `Deployments`: deployments是用来为pods和Replica Sets提供更新用的

* `StatefulSets`:

* `DaemonSet`:

* `Jobs`: 

* `CronJob`: 

* `Garbage Collection`: 

### 1.1 RC和RS的区别

基于相等的就是说只能通过两种操作来设置：

```
environment = production
tier != frontend
```

基于集合的不只是包含等于和不等于两种规则，还可以包含 in 和notin的方式来筛选。

```
environment in (production, qa)
tier notin (frontend, backend)
partition
!partition
```

### 1.2 namespace

不是所有资源都属于某个namespace, 比如Node, PersistentVolume, ClusterRole, ClusterRoleBinding, StorageClass等
具体可以通过如下命令查看

```
# In a namespace
kubectl api-resources --namespaced=true

# Not in a namespace
kubectl api-resources --namespaced=false
```

### 1.3 StatefulSet

首先，StatefulSet 的控制器直接管理的是 Pod。这是因为，StatefulSet 里的不同 Pod 实例，不再像 ReplicaSet 中那样都是完全一样的，而是有了细微区别的。比如，每个 Pod 的 hostname、名字等都是不同的、携带了编号的。而 StatefulSet 区分这些实例的方式，就是通过在 Pod 的名字里加上事先约定好的编号。

其次，Kubernetes 通过 Headless Service，为这些有编号的 Pod，在 DNS 服务器中生成带有同样编号的 DNS 记录

最后，StatefulSet 还为每一个 Pod 分配并创建一个同样编号的 PVC。这样，Kubernetes 就可以通过 Persistent Volume 机制为这个 PVC 绑定上对应的 PV，从而保证了每一个 Pod 都拥有一个独立的 Volume

## 2. 典型操作

### 2.1 版本管理（回滚）

**deployment 版本管理**

Deployment 对象有一个字段，叫作 spec.revisionHistoryLimit，就是 Kubernetes 为 Deployment 保留的“历史版本”个数。

Deployment 控制 ReplicaSet（版本），ReplicaSet 控制 Pod（副本数）。这个两层控制关系一定要牢记。

```
$ kubectl create -f nginx-deployment.yaml --record

$ kubectl rollout history deployment/nginx-deployment
deployments "nginx-deployment"
REVISION    CHANGE-CAUSE
1           kubectl create -f nginx-deployment.yaml --record
2           kubectl edit deployment/nginx-deployment
3           kubectl set image deployment/nginx-deployment nginx=nginx:1.91

$ kubectl rollout history deployment/nginx-deployment --revision=2

$ kubectl rollout undo deployment/nginx-deployment --to-revision=2
deployment.extensions/nginx-deployment

$ kubectl rollout pause deployment/nginx-deployment
deployment.extensions/nginx-deployment paused

$ kubectl rollout resume deploy/nginx-deployment
deployment.extensions/nginx-deployment resumed
```

**daemonset/statefulset 版本管理**

```
$ kubectl get controllerrevision -n kube-system -l name=fluentd-elasticsearch
NAME                               CONTROLLER                             REVISION   AGE
fluentd-elasticsearch-64dc6799c9   daemonset.apps/fluentd-elasticsearch   2          1h

$ kubectl describe controllerrevision fluentd-elasticsearch-64dc6799c9 -n kube-system
```

DaemonSet Controller 就可以使用这个历史 API 对象，对现有的 DaemonSet 做一次 PATCH 操作（等价于执行一次 kubectl apply -f “旧的 DaemonSet 对象”），从而把这个 DaemonSet“更新”到一个旧版本。你会发现，DaemonSet 的 Revision 并不会从 Revision=2 退回到 1，而是会增加成 Revision=3。这是因为，一个新的 ControllerRevision 被创建了出来。

与此同时，DaemonSet 使用 ControllerRevision，来保存和管理自己对应的“版本”。而且，StatefulSet 也是直接控制 Pod 对象的，那么它也在使用 ControllerRevision 进行版本管理

deployment通过维护多个版本的replicaset来控制多版本

### 2.2 查看serviceAccount与role & clusterRole的对应关系

```
# kubectl get rolebindings,clusterrolebindings --all-namespaces -o custom-columns='KIND:kind,NAMESPACE:metadata.namespace,NAME:metadata.name,SERVICE_ACCOUNTS:subjects[?(@.kind=="ServiceAccount")].name'
```

### 2.3 查看etcd的信息

通过证书访问etcd信息

```
/root/local/bin/etcdctl \
--endpoints=${ETCD_ENDPOINTS} \
--ca-file=/etc/kubernetes/ssl/ca.pem \
--cert-file=/etc/flanneld/ssl/flanneld.pem \
--key-file=/etc/flanneld/ssl/flanneld-key.pem \
ls ${FLANNEL_ETCD_PREFIX}/subnets
```

### 2.4 如何访问集群

with kubectl proxy

```
kubectl proxy --port=8100 --address=0.0.0.0 --accept-hosts='^localhost$,^127\.0\.0\.1$,^192.168.2.18$'
or
kubectl proxy --port=8100 --address=0.0.0.0 --accept-hosts='^*$'
```

without kubectl proxy

```
curl -k --key /etc/kubernetes/pki/ca.key --cert /etc/kubernetes/pki/ca.crt https://192.168.2.18:6443/api/v1
```

### 2.5 查看开启和未开启的admission control

```
kubectl exec -ti pod kube-apiserver-xxx -n kube-system
kube-apiserver -h | grep enable-admission-plugins
```

### 2.6 在线修改k8s模块配置

kubelet会自动监听/etc/kubernetes/manifests内文件(static pod)的变化，直接修改这些文件即可触发kubelet自动更新

如果已经部署完成，使用sed修改yaml配置，即可自动生效。不建议使用vim修改（可能会导致文件inode改变，产生新的文件，导致无法触发kubelet）

``
sed -e "s/- --address=127.0.0.1/- --address=0.0.0.0/" -i /etc/kubernetes/manifests/kube-controller-manager.yaml
sed -e "s/- --address=127.0.0.1/- --address=0.0.0.0/" -i /etc/kubernetes/manifests/kube-scheduler.yaml
```

## 3. 最佳实践

### 3.1 驱逐与迁移

调整pod eviction优先级(仅限node资源不足时，kubelet产生的迁移): BestEffort > Burstable > Guaranteed。

node not ready时，controller-manager会迁移所有pod

由于controller-manager的驱逐依靠kubelet心跳，心跳超时的原因有很多，大部分和节点本身无关（软件层面问题）。因此除非满足如下需求，不然请尽量关闭 kube-controller-manager 的驱逐功能，即把驱逐的超时时间设置非常长，同时把一级／二级驱逐速度设置为 0

* 业务方要用正确的姿势使用容器，如数据与逻辑分离，无状态化，增强对异常处理等
* 分布式存储
* 可靠的 Service／DNS 服务或者保持异地重建后的 IP 不变

### 3.2 pod如何获得真实的client地址

将Service的spec.externalTrafficPolicy 字段设置为local，这就保证了所有Pod通过Service 收到请求之后，一定可以看到真正的、外部 client 的源地址。

### 3.3 

kubelet --eviction-hard=imagefs.available<10%,memory.available<500Mi,nodefs.available<5%,nodefs.inodesFree<5% --eviction-soft=imagefs.available<30%,nodefs.available<10% --eviction-soft-grace-period=imagefs.available=2m,nodefs.available=2m --eviction-max-pod-grace-period=600

Kubernetes 计算 Eviction 阈值的数据来源，主要依赖于从 Cgroups 读取到的值，以及使用 cAdvisor 监控到的数据。

而当 Eviction 发生的时候，kubelet 具体会挑选哪些 Pod 进行删除操作，就需要参考这些 Pod 的 QoS 类别了。

首当其冲的，自然是 BestEffort 类别的 Pod。

其次，是属于 Burstable 类别、并且发生“饥饿”的资源使用量已经超出了 requests 的 Pod。

最后，才是 Guaranteed 类别。并且，Kubernetes 会保证只有当 Guaranteed 类别的 Pod 的资源使用量超过了其 limits 的限制，或者宿主机本身正处于 Memory Pressure 状状态时，Guaranteed 的 Pod 才可能被选中进行 Eviction 操作。

cpuset
首先，你的 Pod 必须是 Guaranteed 的 QoS 类型；
然后，你只需要将 Pod 的 CPU 资源的 requests 和 limits 设置为同一个相等的整数值即可。

### 3.4 容器GC问题

container的GC主要有3个用户定义变量：

MinAge：容器被GC的最短时间

MaxPerPodContainer: 允许每个PodContainer中死容器的最大数目,PodContainer指1个Container而非pod

MaxContainers：死容器的最大数目

Minage=0，MaxPerPodContainer和MaxContainers <0, 表示禁用这些变量

GC用于unidentified、deleted或超出边界的容器(3个用户定义变量)。

最旧的container通常首先被移除。如果

MaxPerPodContainer>MaxContainers,maxperpodcontainer会进行调整，直至降级为1，并逐出最旧的容器。
pods所拥有的已删除的容器一旦超过MinAge，就会被删除。未由Kubelet管理的容器不受容器垃圾收集的约束。

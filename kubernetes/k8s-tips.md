---
# introduce

## 概念介绍

* `replication controller(rc)`: RS支持新的基于集合（ set-based）的选择器，而RC只支持基于相等（ equality-based ）的选择器

* `replica set(rs)`: rs的selector选择器多了两种除了相等和非相等之外的筛选模式，使得筛选和管理pod更为灵活

* `Deployments`: deployments是用来为pods和Replica Sets提供更新用的

* `StatefulSets`:

* `DaemonSet`:

* `Jobs`: 

* `CronJob`: 

* `Garbage Collection`: 

### RC和RS的区别

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

### namespace

不是所有资源都属于某个namespace, 比如Node, PersistentVolume, ClusterRole, ClusterRoleBinding, StorageClass等
具体可以通过如下命令查看

```
# In a namespace
kubectl api-resources --namespaced=true

# Not in a namespace
kubectl api-resources --namespaced=false
```



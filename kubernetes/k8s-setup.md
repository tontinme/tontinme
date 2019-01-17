# Kubernetes Setup

## Table of Content

[install through kubeadm](#Install through kubeadm)
[install ipvs](#Install IPVS)
[install metrics-server](#Install metrics-server)
[apply example](#Running example)

## Install through kubeadm

| role | count | IPs | OS |
|---|---|---|---|
| master | 1 | 192.168.2.61 | CentOS 7.5 |
| worker | 2 | 192.168.2.62-63 | CentOS 7.5 |


部署文档

安装kubeadm

[Installing kubeadm](https://kubernetes.io/docs/setup/independent/install-kubeadm/)

+ 检查机器
+ 安装runtime(docker, rkt, etc..)
+ 安装kubeadm, kubelet, kubectl

安装kubernetes

[Creating a single master cluster with kubeadm](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)

**如果使用ipvs代替iptables，请先阅读ipvs install文档，修改配置后，再执行init命令**

+ 检查参数
+ 执行kubeadm init
+ 测试kubectl
+ 安装CNI(flannel, calico, etc..)
+ 增加worker节点(join)
+ 部署dashboard
+ 功能测试
+ 删除&重部署集群

init脚本

检查网络，下载镜像

```
$ kubeadm config images pull

[config/images] Pulled k8s.gcr.io/kube-apiserver:v1.12.2
[config/images] Pulled k8s.gcr.io/kube-controller-manager:v1.12.2
[config/images] Pulled k8s.gcr.io/kube-scheduler:v1.12.2
[config/images] Pulled k8s.gcr.io/kube-proxy:v1.12.2
[config/images] Pulled k8s.gcr.io/pause:3.1
[config/images] Pulled k8s.gcr.io/etcd:3.2.24
[config/images] Pulled k8s.gcr.io/coredns:1.2.2
```

检查默认配置

```
$ kubeadm config print-default
```

确认配置，开始部署

```
$ kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.2.61
[init] using Kubernetes version: v1.12.2
[preflight] running pre-flight checks
[preflight/images] Pulling images required for setting up a Kubernetes cluster
...
```
配置kubectl

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

安装flannel

```
$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml

clusterrole.rbac.authorization.k8s.io/flannel created
clusterrolebinding.rbac.authorization.k8s.io/flannel created
serviceaccount/flannel created
configmap/kube-flannel-cfg created
daemonset.extensions/kube-flannel-ds-amd64 created
daemonset.extensions/kube-flannel-ds-arm64 created
daemonset.extensions/kube-flannel-ds-arm created
daemonset.extensions/kube-flannel-ds-ppc64le created
daemonset.extensions/kube-flannel-ds-s390x created

# kubectl get pods --all-namespaces
NAMESPACE     NAME                             READY   STATUS    RESTARTS   AGE
kube-system   coredns-576cbf47c7-nqd4k         1/1     Running   0          14m
kube-system   coredns-576cbf47c7-vppkx         1/1     Running   0          14m
kube-system   etcd-next-1                      1/1     Running   0          13m
kube-system   kube-apiserver-next-1            1/1     Running   0          13m
kube-system   kube-controller-manager-next-1   1/1     Running   0          13m
kube-system   kube-flannel-ds-amd64-xfd5c      1/1     Running   0          103s
kube-system   kube-proxy-cnsnk                 1/1     Running   0          14m
kube-system   kube-scheduler-next-1            1/1     Running   0          13m
```

登录worker节点，加入集群

```
token=$(kubeadm token list | grep token | awk '{print $1}')
hash=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')

kubeadm join 192.168.2.61:6443 --token $token --discovery-token-ca-cert-hash sha256:$hash
```

安装dashboard [链接](https://github.com/kubernetes/dashboard)

官方文档默认会存在证书问题，浏览器无法登录，报错提示**NET::ERR_CERT_INVALID**

使用如下方法重新生成证书 [链接](https://github.com/kubernetes/dashboard/issues/2954)

```
$ mkdir certs
$ openssl req -nodes -newkey rsa:2048 -keyout certs/dashboard.key -out certs/dashboard.csr -subj "/C=/ST=/L=/O=/OU=/CN=kubernetes-dashboard"
$ openssl x509 -req -sha256 -days 365 -in certs/dashboard.csr -signkey certs/dashboard.key -out certs/dashboard.crt
$ kubectl apply secret generic kubernetes-dashboard-certs --from-file=certs -n kube-system
$ kubectl apply -f kubernetes-dashboard.yaml
```

下载dashboard的configmap，修改使用NodePort（默认是ClusterPort）

```
$ wget https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

#修改dashboard service一节, type使用nodeport
...
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30001
...

$ kubectl apply -f kubernetes-dashboard.yaml
```

使用kube-proxy登录

```
kubectl proxy
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
```

使用NodePort登录, https://<host-ip>:30001

需要创建admin权限的user用于登录 [链接](https://github.com/kubernetes/dashboard/wiki/Creating-sample-user)

```
$ cat dashboard-adminuser.yaml
# ------------ ServiceAccount ----------- #
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system

# ------------ ClusterRoleBinding ----------- #
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
```

查看刚刚创建的用户的token

```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

Name:         admin-user-token-wdsln
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: admin-user
              kubernetes.io/service-account.uid: 5ab909d8-e633-11e8-b17d-52540023d0a0

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1025 bytes
namespace:  11 bytes
token:      eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLTZnbDZsIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJiMTZhZmJhOS1kZmVjLTExZTctYmJiOS05MDFiMGU1MzI1MTYiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06YWRtaW4tdXNlciJ9.M70CU3lbu3PP4OjhFms8PVL5pQKj-jj4RNSLA4YmQfTXpPUuxqXjiTf094_Rzr0fgN_IVX6gC4fiNUL5ynx9KU-lkPfk0HnX8scxfJNzypL039mpGt0bbe1IXKSIRaq_9VW59Xz-yBUhycYcKPO9RM2Qa1Ax29nqNVko4vLn1_1wPqJ6XSq3GYI8anTzV8Fku4jasUwjrws6Cn6_sPEGmL54sq5R4Z5afUtv-mItTmqZZdxnkRqcJLlg2Y8WbCPogErbsaCDJoABQ7ppaqHetwfM_0yMun6ABOQbIwwl8pspJhpplKwyo700OSpvTT9zlBsu-b35lzXGBRHzv5g_RA
```

使用token登录dashboard


## Install IPVS

[ipvs](https://github.com/kubernetes/kubernetes/blob/master/pkg/proxy/ipvs/README.md)

## Install metrics-server

[metrics-server](https://github.com/kubernetes-incubator/metrics-server)

git下载项目

按照说明文档，执行安装

```
cd metrics-server/
kubectl apply -f deploy/1.8+/
```

等待几分钟，执行如下命令，查看是否部署成功

```
[root@next-1 1.8+]# kubectl top node
NAME     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
next-1   167m         2%     1623Mi          38%
next-2   31m          0%     574Mi           13%
next-3   51m          0%     645Mi           15%

kubectl top pods

```

查看metrics-server是否成功运行

```
# 查看apiservice
kubectl get apiservice
...
v1beta1.metrics.k8s.io                 kube-system/metrics-server   True        41m
...

kubectl describe apiservice v1beta1.metrics.k8s.io
...
Status:
  Conditions:
    Last Transition Time:  2018-11-18T12:02:09Z
    Message:               all checks passed
    Reason:                Passed
    Status:                True
    Type:                  Available
...
```

如果一直提示如下报错

```
[root@next-1 1.8+]# kubectl top node
error: metrics not available yet
```

可能遇到hostname解析问题，需要修改如下[链接](https://github.com/kubernetes-incubator/metrics-server/issues/131)

打开metrics-server-deployment.yaml

```
# 添加如下内容
        command:
        - /metrics-server
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP

kubectl apply -f metrics-server-deployment.yaml
```

## Running example

基于安全原因，k8s默认不允许调度pods到master节点。执行如下命令，允许其调度

```
kubectl taint nodes --all node-role.kubernetes.io/master-
```

运行一个nginx示例


```
# kubectl apply -f nginx.yml

# cat nginx.yml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```


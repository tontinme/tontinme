# 证书介绍文档

## Table of Contents

[TLS证书简介](#TLS证书简介)

[认证](#认证)

[授权](#授权)

[准入控制](#准入控制)

[手动创建证书](#手动创建证书)

[证书续约](#证书续约)

[附录](#附)

# TLS证书简介

```
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            b4:1e:8b:32:69:96:d0:0b
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=kubernetes
        Validity
            Not Before: Sep 20 00:15:03 2019 GMT
            Not After : Sep 17 00:15:03 2029 GMT
        Subject: O=system:masters, CN=kube-apiserver-kubelet-client
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:ec:a6:65:f6:31:e4:05:0e:d0:85:5c:6d:37:12:
                    2a:2c:48:1a:4f:83:1f:80:ea:dd:02:59:2b:c5:83:
                    c8:56:2e:eb:f8:f9:ce:6f:5c:b2:64:89:e4:ec:5b:
                    ...
                    4d:f3:d8:b8:18:61:ae:3d:b2:94:ad:1a:b8:af:1a:
                    bb:67
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
    Signature Algorithm: sha256WithRSAEncryption
         2a:5b:0f:fc:62:5a:f0:3f:22:b6:7a:ff:5e:40:85:05:9c:1c:
         a7:b4:b2:78:c4:3d:f0:a3:0d:d5:11:22:09:8f:a5:3b:58:63:
         1c:34:a4:34:a6:98:5e:48:21:d9:77:d3:99:a6:af:ef:48:81:
         ...
         cd:6c:06:eb:d8:54:0d:38:ea:ac:91:03:76:88:41:c0:05:46:
         20:b1:30:c6:d8:91:40:eb:e1:85:b9:ce:f3:67:48:f2:fb:93:
         a9:fb:f9:58
```

证书包含主体公钥、身份信息，证书授权中心，签名信息等。签名信息需要使用名为kubernetes的CA的公钥进行验证，如果解密出来的签名信息和本地对比一致，则验证通过）。签名命令

```
# openssl verify -CAfile ca.crt apiserver-kubelet-client.crt
apiserver-kubelet-client.crt: OK
```


> 认证：识别用户身份
> 授权：用户有哪些权限
> 准入控制：作用于kubernetes对象，通过合理的权限管理，保证系统安全可靠

# 认证(Authentication)

支持的认证策略

* x509 client certs
* static token file
* bootstrap tokens
* static password file
* service account tokens
* openID connect tokens
* webhook token authentication
* authticating proxy
* anonymous requests
* user impersonation
* client-go credential plugins

## x509 TLS双向认证

双向认证，比如

```
cd /etc/kubernetes
curl --cacert ./pki/ca.crt https://1.2.4.8:6443/api/v1 --cert ./pki/apiserver-kubelet-client.crt --key ./pki/apiserver-kubelet-client.key
```

> --cacert: 告诉curl，使用该CA对url进行证书认证
> --cert & --key: 将curl client的证书传递给url，供对方认证client

单向认证 - 只认证对端网站

```
curl --cacert ./ca.crt https://xxx
```

单向认证 - 只让url认证自己

```
curl -k https://xxx/ --cert ./client.crt --key client.key
```

## kubernetes(kubeadm)证书介绍

### pki

    > ca.crt - client ca file (CA, 用来签名发放访问client的crt, 比如下面的apiserver-etcd-client.crt等)
    > ca.key - client key file
    > apiserver-etcd-client.crt - cert file (etcd访问apiserver时，apiserver返回该证书供etcd验证。由etcd/ca.crt签名)
    > apiserver-etcd-client.key - key file
    > apiserver-kubelet-client.crt - cert file (kubelet访问apiserver时，apiserver返回该证书供kubelet验证)
    > apiserver-kubelet-client.key - key file
    > sa.pub - service account key file
    > sa.key - service account key file
    > apiserver.crt - tls cert file (默认的server端证书, 各组件比如kube-flannel, proxy访问apiserver时，会校验该证书)
    > apiserver.key - tls private key file
    > front-proxy-ca.crt - client ca file (different with ca.crt. kube-proxy which support an extension API server)
    > front-proxy-ca.key - client key file
    > front-proxy-client.crt - cert file (由front-proxy-ca.crt签名, 仅在extension apiserver与apiserver通信时使用)
    > front-proxy-client.key - key file

额外增加的两个证书

    > controller-manager.crt - controller-manager可以作为server端,对外提供CA服务，此时使用该证书。如不指定，controller-manager会自动生成一个1年有效期的证书. 类似于apiserver.crt
    > controller-manager.key
    > scheduler.crt - kube-scheduler也支持server端的证书，提供healthcheck，metrics等服务，默认端口为10259
    > scheduler.key

pki/etcd

    > etcd/ca.crt - CA, 负责etcd相关证书的签名
    > etcd/ca.key
	> etcd/healthcheck - client.crt (liveness probe)
	> etcd/healthcheck
	> etcd/peer.crt - cert file (etcd > etcd)
	> etcd/peer.key
	> etcd/server.crt - cert file (apiserver访问etcd时，etcd返回该证书，供apiserver验证)
	> etcd/server.key

/etc/kubernetes

	> admin.conf - (admin user访问apiserver时，提供其中的证书给apiserver验证)
	> controller-manager.conf - (kube-controller-manager作为client，访问apiserver时使用)
	> kubelet.conf - (kubelet访问apiserver时使用, only for master node)
	> scheduler.conf - (kube-scheduler访问apiserver时使用)

里面的结构如下

```
clusters:
- cluster:
    certificate-authority-data: xxx  // CA证书, 即/etc/kubernetes/pki/ca.crt。用来验证apiserver返回的证书, 比如apiserver.crt
users:
- name: kubernetes-admin
  user:
    client-certificate-date: xxx // client证书，client提供给apiserver，供其验证client合法性, 即client-xxx.crt
    client-key-data: xxx // PrivateKey，给client证书签名的
```

kubelet(worker node)
	kubelet-client-2019-05-10-14-45-23.pem //kubelet访问apiserver时，提供该证书
	kubelet-client-2019-05-10-14-46-26.pem
	kubelet-client-current.pem -> /var/lib/kubelet/pki/kubelet-client-2019-05-10-14-46-26.pem
	kubelet.crt  // kubelet也可对外提供服务，端口10250。有client访问该端口时，kubelet提供该证书供验证
	kubelet.key

## Service Account Token

用户Pod访问APIServer等内部资源，

```
# ls /var/run/secrets/kubernetes.io/serviceaccount/
ca.crt namespace token
```

> ca.crt - pod通过ca.crt验证apiserver的证书是否合法（使用ca.crt中的公钥进行RSA解密证书，获得内含的数字签名hash值，与本地计算的SHA1 hash值进行比较）

service account的token保存在secret中(形式为POD-NAME-token-xxx)
	kube-proxy
		kube-proxy-token-xxx
	flannel
		flannel-token-xxx

```
[root@umstor18 kubernetes]# kubectl get sa node-exporter -n storage-system -o yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: node-exporter
  namespace: storage-system
secrets:
- name: node-exporter-token-4hpcd

# kubectl get secret node-exporter-token-4hpcd -n storage-system -o json | jq -r '.data."ca.crt"' | base64 -d | openssl x509 -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 0 (0x0)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN=kubernetes
        Validity
            Not Before: May 10 06:45:13 2019 GMT
            Not After : May  7 06:45:13 2029 GMT
        Subject: CN=kubernetes
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
...
```


# 授权(Authorization)

识别是否有相应操作权力。授权者，通过组合属性（用户属性，资源属性，实体）的策略向用户授予访问权限。

支持的鉴权策略

* Node
* ABAC
* RBAC
* Webhook

## Node

专门为配合NodeRestriction(限制其只能操作本机资源)准入控制来限制kubelet的一种授权方式，使其仅可访问node, endpoint, pod, service以及secret, configmap, pv, pvc等相关资源。在apiserver中使用以下配置开启node鉴权机制

```
KUBE_ADMISSION_CONTROL="...,NodeRestriction,..."
KUBE_API_ARGS="...,--authorization-mode=Node,..."
```

由于要对整个集群的pod，node等资源进行操作，权限太大，所以需要设置准入控制NodeRestriction。

## RBAC

> Role: 角色
> Subject: 被作用者，包括user, group, serviceacount
> RoleBinding: 绑定关系

# 准入控制(Admission Control)

判断你的操作是否符合集群要求，用户还可以根据自己的需求定义准入插件来管理集群。kubernetes将准入模块分为三种，validating(验证型)，mutating(修改型)以及两者兼有。

官方有推荐默认的内置规则。

准入控制是有序的，不同的顺序会影响kubernetes的性能，建议使用官方配置

# 手动创建证书(用于apiserver访问其他组件)

Step 1. 创建自签名CA证书

```
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=${MASTER_IP}" -days 10000 -out ca.crt
```

Step 2. 创建一个证书请求并签名(以scheduler为例)

```
1. 私钥
openssl genrsa -out apiserver-scheduler.key 2048

2. 创建csr
2.1 准备csr.conf，使用csr.conf创建
openssl req -new -key apiserver-scheduler.key -out apiserver-scheduler.csr -config scheduler-csr.conf
or
2.2 简单场景，执行指定csr参数
HN=`hostname -s`
openssl req -new -key apiserver-scheduler.key -out apiserver-scheduler.csr -subj "/CN=$HN"

3. 签名
3.1 使用csr.conf签名
openssl x509 -req -in apiserver-scheduler.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out apiserver-scheduler.crt -days 10000 \
  -extensions v3_ext -extfile scheduler-csr.conf
3.2 简单场景签名
openssl x509 -req -in apiserver-scheduler.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out apiserver-scheduler.crt -days 10000
```

这样就获得了一个apiserver访问kube-scheduler的一组证书, apiserver-scheduler.{key,crt}

如果apiserver需要访问其他组件，再重复步骤2生成一组即可.


# 证书续约(renew)

Step 1): Backup old certs and kubeconfigs

```
mkdir /etc/kubernetes.bak
cp -r /etc/kubernetes/pki/ /etc/kubernetes.bak
cp /etc/kubernetes/*.conf /etc/kubernetes.bak
```

Step 2): Renew all certs

```
kubeadm alpha certs renew all --config kubeadm.yaml
```

or

```
kubeadm --config ../kubernetes.bak/kubeadm.yml init phase certs apiserver
kubeadm --config ../kubernetes.bak/kubeadm.yml init phase certs apiserver-etcd-client
kubeadm --config ../kubernetes.bak/kubeadm.yml init phase certs apiserver-kubelet-client
kubeadm --config ../kubernetes.bak/kubeadm.yml init phase certs etcd-healthcheck-client
kubeadm --config ../kubernetes.bak/kubeadm.yml init phase certs etcd-peer
kubeadm --config ../kubernetes.bak/kubeadm.yml init phase certs etcd-server
kubeadm --config ../kubernetes.bak/kubeadm.yml init phase certs front-proxy-client
```

Step 3): Renew all kubeconfigs

```
kubeadm alpha kubeconfig user --client-name=admin
kubeadm alpha kubeconfig user --org system:masters --client-name kubernetes-admin  > /etc/kubernetes/admin.conf
kubeadm alpha kubeconfig user --client-name system:kube-controller-manager > /etc/kubernetes/controller-manager.conf
kubeadm alpha kubeconfig user --org system:nodes --client-name system:node:$(hostname) > /etc/kubernetes/kubelet.conf
kubeadm alpha kubeconfig user --client-name system:kube-scheduler > /etc/kubernetes/scheduler.conf

modify api endpoint to vip

chown root:root {admin,controller-manager,kubelet,scheduler}.conf
chmod 600 {admin,controller-manager,kubelet,scheduler}.conf
```

Another way to renew kubeconfigs

```
# kubeadm init phase kubeconfig all --config kubeadm.yml --kubeconfig-dir /tmp/123

[kubeconfig] Using kubeconfig folder "/tmp/123"
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "admin.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "scheduler.conf" kubeconfig file
```

Step 4): Copy certs/kubeconfigs and restart Kubernetes services

```
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
```

其他证书续约

> kubelet: 可以开启自动续约
> etcd: 会自动加载更新后的证书

```
restart kube-apiserver
restart kube-controller-manager
restart kube-scheduler

or 

systemctl restart kubelet
```

Step 5): Verify master component certificates - should all be 1 year in the future

```
# Cert from api-server
echo -n | openssl s_client -connect localhost:6443 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -noout -dates
# Cert from controller manager
echo -n | openssl s_client -connect localhost:10257 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -noout -dates
# Cert from scheduler
echo -n | openssl s_client -connect localhost:10259 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -noout -dates
```

check kubelet

```
echo -n | openssl s_client -connect localhost:10250 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -noout -text
```



# 附: kubeadm renew流程

kubeadm alpha certs renew all 
1.14.1
	> kubernetes/cmd/kubeadm/app/cmd/alpha/certs.go
		certsphase.GetDefaultCertList
           KubeadmCertRootCA,
           KubeadmCertAPIServer,
           KubeadmCertKubeletClient,
           // Front Proxy certs
           KubeadmCertFrontProxyCA,
           KubeadmCertFrontProxyClient,
           // etcd certs
           KubeadmCertEtcdCA,
           KubeadmCertEtcdServer,
           KubeadmCertEtcdPeer,
           KubeadmCertEtcdHealthcheck,
           KubeadmCertEtcdAPIClient,

1.15.0
	> kubernetes/cmd/kubeadm/app/cmd/alpha/certs.go -> renewal.NewManager
		kubernetes/cmd/kubeadm/app/phases/certs/renewal/manager.go
        > certsphase.GetDefaultCertList
            ...
		> kubeConfigs
			admin.conf
            controller-manager.conf
            scheduler.conf


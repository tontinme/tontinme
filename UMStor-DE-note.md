# 名词解释

目前存储一体机包含如下主要组件

* DE
    * DE-Server     # 服务器安装，配置，及部署管理
    * DE-Agent      # 服务器自动发现和注册，执行系统安装
* LCM               # 封装ansible-playbook，并对外提供restful api服务


# DE流程介绍

UMStor-DE最初是针对UMStor存储一体机设计的部署引擎。包含如下功能

1. 操作系统定制
2. 操作系统安装
3. 自动配置LCM（LCM是UMStor部署工具）
4. 自动触发UMStor安装程序

工作原理及流程如下

## 1. 准备系统镜像（qcow2格式）

需要对系统镜像做一些定制，比如系统参数调优，关闭selinux，关闭numa

如果是安装节点，需要内置DE-Server和LCM-Server。

## 2. 安装系统

pxe启动服务器，自动注册到DE-Server，通过dd方式将qcow2镜像写到系统盘，设置主机名及IP等信息

## 3. 初始化LCM

LCM本身基于ansible-playbook，需要填写集群信息等配置文件。DE基于存储一体机的场景，将大部分配置参数固定下来，仅保留尽可能少的必要参数

DE安装完所有节点的系统后，传递环境配置信息，更新LCM配置，启动LCM。

更新的LCM配置包括

```
LCM监听地址
LCM离线源等依赖组件信息
集群VIP，服务端口等信息
```

## 4. 执行UMStor集群部署

DE收集环境信息，根据一体机场景预先分配各节点角色，提供API发送给LCM，执行集群部署。

API内容包括：

```
节点角色分配
集群网络信息
每个节点的网络信息
每个节点的磁盘信息
```

# Q&A

## DE如何对接ansible

目前对umstor，由lcm负责封装ansible，并暴露api。DE本身还不支持ansible。

DE对接ansible的话，有几个方面需要考虑

1. DE现在跑在docker里面，需要提供支持ansible的docker image
2. ansible的配置文件(group_var, host_var等)，需要人工填写还是DE填写
3. DE是用golang写的，如果调用ansible命令的话，执行命令和日志都如何管理都需要考虑

## DE支持虚拟机

DE设计的时候仅考虑了物理机部署，且仅测试过存储一体机。如果需要支持虚拟机，有一定的开发工作量，需要调研。

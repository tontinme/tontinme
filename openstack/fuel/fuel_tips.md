# Storage node replace NIC 

## 1. 备份storage node网卡配置

    /etc/sysconfig/network-scripts/ifcfg-<interface name>

## 2. 正确关机storage node

## 3. 替换新网卡

## 4. 更新storage node中的MAC Address

```
更新70文件
更新/etc/sysconfig/network-scripts/ifcfg-<interface name>中的MAC地址
```

## 5. 更新Fuel master & Nailgun DB中的MAC Address

### Step 1. 备份postgres数据库

进入postgres数据库，并备份

```
dockerctl shell postgres
su postgres
pg_dump nailgun --clean > /tmp/nailgun_db_backup_`date '+%F-%H%M'`.sql 
exit
```

拷贝dump出来的db文件，放到docker共享目录。之后退出docker

```
cp /tmp/nailgun_db_backup*.sql /var/www/nailgun/
exit
```

获得storage node之前旧网卡的mac

    dockerctl shell cobbler cobbler system report --name=node-3 > cobbler_report_before_update.txt

### Step 2. 更新dump db中的MAC地址

```
cp /var/www/nailgun/nailgun_db_backup*.sql /var/www/nailgun/updated_nailgun_db_backup.sql
sed -i 's/b8:2a:72:cf:a6:1a/44:a8:42:16:67:83/g' /var/www/updated_nailgun_db_backup.sql - eth0
sed -i 's/b8:2a:72:cf:a6:1c/44:a8:42:16:67:85/g' /var/www/updated_nailgun_db_backup.sql - eth1
sed -i 's/b8:2a:72:cf:a6:1e/44:a8:42:16:67:87/g' /var/www/updated_nailgun_db_backup.sql - eth2
sed -i 's/OLD_ETH_MAC_ADDRESS_HERE/44:a8:42:16:67:89/g' /var/www/updated_nailgun_db_backup.sql - eth3
```

### Step 3. 将dump db恢复到Nailgun DB

```
dockerctl shell postgres - to enter Postgres container
cp /var/www/nailgun/updated_nailgun_db_backup.sql /tmp/
chown postgres:postgres /tmp/updated_nailgun_db_backup.sql
chmod 0644 /tmp/updated_nailgun_db_backup.sql 
su postgre
```

### Step 4. 备份现有Nailgun DB

```
pg_dump nailgun --clean > /tmp/nailgun_db_backup_`date '+%F-%H%M'`.sql
```

将之前update MAC的DB导入到Nailgun

```
psql nailgun < /tmp/updated_nailgun_db_backup.sql
exit
```

### Step 5. 将最新的sql备份拷贝到docker的共享目录

```
cp /tmp/nailgun_db_backup_*.sql /var/www/nailgun/ 
exit
```

## 6. 重启各服务

```
dockerctl restart nailgun
dockerctl restart nginx
dockerctl restart ostf
dockerctl restart cobbler
dockerctl shell cobbler cobbler sync 
```

获取最新MAC，验证

```
dockerctl shell cobbler cobbler system report --name=node-3 > cobbler_report_after_update.txt
```

等待2-3min，执行fuel node list查看MAC是否更新

# Some docker commands on Fuel node

## docker

### start a new docker container with the specified commands

```
docker run [options] imagename [command]
```

### 导入一个docker image

    docker load -i (archive file)o

支持的格式包括: .tar, .tar.gz, .tar.xz. 不支持lrz

### 保存一个image到文件


    docker save image > image.tar

## dockerctl

### build and run storage container, then run application container.

    dockerctl build all 

### 从镜像启动一个container，如果container已存在，将确保它处于运行状态

    dockerctl start <appname> [--attach]

optionally, --attach option can be used to monitor the process and view its stdout and stderr.

### display the entire container log for /app/

    dockerctl log <appname>

### create a shell or run a command

    dockerctl shell <appname> [command]

### Other

Containers are automatically restarted by supervisord. If you need to stop a container for any reason, first run supervisorctl stop /app/, and then dockerctl stop /app/


# Adding, REdeploying and Replacing Nodes

## Redeploy a Non-Controller Node

重新部署一个节点意味着你想更改一台线上机器的角色。比如把一台compute节点的机器redeploy为storage节点

1. live-migratio迁移所有该节点上的实例
2. 如果有必要，备份该机器上的配置
3. 在fuel web界面，删除该节点
4. 点击『部署变更』
5. 等待节点删除成功，状态变为未分配
6. 在fuel web界面添加该节点到storage角色
7. 点击部署变更
8. 等待fuel部署完成

## Add a Non-controller node

1. 配置并上架物理机
2. 启动物理机，等待Fuel发现该node
3. 将node加入cluster，并配置磁盘，网络
4. 点击『变更部署』，等待部署完成

大多数运行的服务不会受到影响。少数比如haproxy和一些其他服务部署过程中会被重启

## Add a mongoDB node

当集群已经处于运行状态，就不能通过Fuel UI添加mongoDB node，只能通过CLI进行

Fuel使用mongoDB作为ceilometer的backend. 应该为每个controller node配置mongoDB node。所以当你需要添加controller node时，记得也要添加mongoDB node。

1. Add an entry for each new MongoDB node to the connection parameter in the ceilometer.conf file on each Controller node. This entry needs to specify the new node's IP address for the Management logical network.
2. Open the astute.yaml file on any deployed MongoDB node and determine which node has the primary-mongo role; see MongoDB nodes configuration. Write down the value of the fqdn parameter; you will use this to ssh to this node.
3. Retrieve the db_password value from the Ceilometer configuration section of same file. You will use this password to access the primary MongoDB node.
4. Connect to the MongoDB node that has the primary-mongo role and log into Mongo:

```
ssh ... <fqdn-of-primary-mongo-node>
mongo -u admin -p <db_password> admin
```

5. Configure each MongoDB node to be added to the environment:

    ceilometer:PRIMARY> rs.add ("<management-ip-address-of-node>")

6. Restart the ceilometer services.

## Add a controller node

以下情况下可以增加controller node

* 只部署了一台controller node，为了支持HA，需要增加2台或更多
* 当前环境的controller资源占用过高
* 有controller损坏，需要替换。此时需要先移除故障controller，请参考remove controller的步骤

controller个数必须为奇数

1. 配置controller并加电，等待Fuel发现
2. 在Fuel web界面点击添加node
3. 检查网络连通性
4. 点击『部署变更』
5. 运行「post-deploymet check」

## Remove a Controller node

一般是由于线上有controller损坏，或者需要替换为配置更高的机器

1. 在Fuel Web界面删除该node，并点击部署变更
2. 进入机房移除该node



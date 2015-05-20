# 对已root的android进行手动系统升级

## 线刷系统

### 下载系统镜像

### 打开终端

将adb，fastboot加入系统变量

    export PATH=$PATH:/Volumes/tontinme/develop/adt-bundle-mac-x86_64-20131030/sdk/platform-tools

解压系统镜像

```
$ cd /Volumes/tontinme/hammerhead-lmy47i/
$ ls
bootloader-hammerhead-hhz12f.img        flash-all.sh                            image-hammerhead-lmy47i.zip
flash-all.bat                           flash-base.sh                           radio-hammerhead-m8974a-2.0.50.2.25.img
```

修改flash-all.sh，不要删除系统数据。即去掉**-w**

```
23c23
< fastboot update image-hammerhead-lmy47i.zip
---
> fastboot -w update image-hammerhead-lmy47i.zip
```

### 正式升级系统

手机使用usb连接电脑，并打开debug模式

```
$ adb devices -l
$ adb reboot bootloader
$ sh flash-all.sh
```

等待升级完成即可

## 重新root手机

升级完后，手机仍是解锁的，但是需要重新root

下载unlock bootloader，连接手机到电脑

    # http://download.chainfire.eu/363/CF-Root/CF-Auto-Root/CF-Auto-Root-hammerhead-hammerhead-nexus5.zip

同样的，需要先进入到bootloader

    $ cd /Volumes/tontinme/N5/CF-Auto-Root-hammerhead-hammerhead-nexus5/
    $ adb devices -l
    $ adb reboot bootloader

开始root

    $ sh root-mac.sh

等待手机重启即可

## 开启位置报告

删除google search数据（若找不到，则删除所有登录的google 帐号）

下载Market Unlocker，启用解锁，模拟运营商为version

重新登录google帐号

打开位置报告，打开google now, google fit

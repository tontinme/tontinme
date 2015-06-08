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


# moto G

## bootloader 解锁

使用官方教程获得解锁码

    https://motorola-global-portal.custhelp.com/app/standalone/bootloader/unlock-your-device-b

## root

下载 [CF-Auto-Root-titanumtsds-titanretde-xt1068](http://ligux.com/wp-content/uploads/2015/02/CF-Auto-Root-titanumtsds-titanretde-xt1068.zip) ，没错，我使用了XT1068的自动root包，大家不用担心，为何使用XT1068的可以自动Root，因为在root之前我做了相关功课，发现XT1068和XT1079两个机器，都是双卡，带外置存储卡的机器，而且机器配置基本都相同，除了销售的地方不同之外，所以我坚信使用XT1068的自动Root包可以完成XT1079的Root，果不其然，顺利通过这个方式Root掉了XT1079，方法是：

- 手机开启调试模式，允许usb debugging, enable oem unlock

- 在CMD或者Terminal中执行：fastboot reboot bootloader，或者开机时按住power键和音量下键

- 解压刚才提到的附件，CMD中进入解压附件所在的目录。mac下执行：

    chmod +x ./root-mac.sh && ./root-mac.sh
    (如果提示waiting for devices，那么可以使用adb自带的fastboot执行)
    fastboot boot image/CF-Auto-Root-titanumtsds-titanretde-xt1068.img

- 上一步执行完后系统会自动重启并启动，这时候有一定机率会卡在第一屏不保修文字的警告，如果等待几分钟还没进去系统，就按住电源，音量+，音量-强制重启机器

- 再次开机后进入系统发现系统已经存在了SuperSU了，恭喜你，root成功了

## 刷Recovery，busybox和Gapps

- 先进入bootloader

- 下载附件的这个Recovery文件并解压：[CWM_Touch_Titan_v2.img](http://ligux.com/wp-content/uploads/2015/02/CWM_Touch_Titan_v2.img_.zip)

- 在CMD或者Terminal中执行：屏幕会提示成功

    fastboot flash recovery CWM_Touch_Titan_v2.img

- 这时不能直接从bootloader的菜单中选择“recovery”并进入，先重启手机，进入系统

- 下载superbox工具包[busybox](http://ligux.com/wp-content/uploads/2015/02/busybox.zip) ，下载该zip包后无须解压，直接把zip拷贝到sdcard上

- 下载5.0专用的Gapps包[Gapps](http://rom.ligux.com/gapps/gapps-lp-20141109-signed.zip)，下载该zip包后无须解压，直接把zip拷贝到sdcard上

- 重新进入bootloader, 这个时候会发现Recovery已经被刷上CWM了

- 在Recovery先刷busybox刷机包，成功后先重启机器，再关机进入bootloader

- 在Recovery中刷Gapps包，刷成功后要Wipe data/factory reset，然后重启机器，这个时候进去系统发现久违的Root和Gapps回来了

## 官方底包在此

http://bbs.ihei5.com/thread-335899-1-1.html

## 官方恢复工厂镜像链接

https://motorola-global-portal.custhelp.com/app/standalone/bootloader/recovery-images

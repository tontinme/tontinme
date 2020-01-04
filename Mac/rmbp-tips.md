[Show hidden files in Finder](Show-hidden-files-in-Finder)
[homebrew](#homebrew)
[rdm retina](#rdm-retina)
[parallels desktop](#Parallels-Desktop)


# Show hidden files in Finder

	显示隐藏文件
	defaults write com.apple.finder AppleShowAllFiles -bool true
	killall Finder
	恢复隐藏文件
	defaults write com.apple.finder AppleShowAllFiles -bool false
	killall Finder
# homebrew
	brew search $package
	brew install $package
	brew list	#列出已安装的软件包
	brew remote $package
	brew info $package	#查看软件包信息
	brew deps $package	#列出包的依赖关系
	brew update	#更新brew
	brew outdated	#列出过时的软件包(已安装但不是最新版)
	brew upgrade & brew upgrade $package	#更新过时的软件包（全部或指定）
	#定制自己的软件包
	1. 找到源码位置
	http://foo.com/bar.1.0.tgz
	2. 建立自己的formula
	brew create http://foo.com/bar.1.0.tgz
	3. 编辑formula, 上一步成功后，brew会自动打开新建的formula进行编辑，也可以使用如下
	命令编辑
	brew edit bar
	homebrew自动建立的formula已经包含了基本的configure和make install命令，对大部分软件
	来说不需要修改，退出编辑即可
	4. 安装自定义的软件包
	brew install bar

proxychains
    用于配置命令行使用shadowsocks代理
    1. git
    git可以直接配置翻墙
    git config --global http.proxy 'socks5://127.0.0.1:8090'
    git config --global https.proxy 'socks5://127.0.0.1:8090'
    其中socks地址为本机的shadowsocks监听地址
    2. 配置proxychain
    使用proxychain，这样可以支持所有命令，比如pip
    brew install proxychains-ng
    配置proxychains
    $ vim /usr/local/etc/proxychains.conf
    配置[ProxyList]，增加socks
    socks4 ▸127.0.0.1 1080
    socks5 ▸127.0.0.1 1080
    具体命令使用
    proxychains4 git push
    3. homebrew使用代理
    ALL_PROXY=socks5://localhost:1080 brew install xxx

# rdm retina

https://wacky.one/blog/macos-hi-dpi/

## 1. 打开系统HiDPI

```
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool YES
```

## 2. 禁用SIP (macOS 10.11及以上)

macOS 10.11 El Capitan 开始默认启用 System Integrity Protection (SIP) 防止系统文件被修改。因为配置文件需要放在系统文件夹中，要禁用 SIP。

开机或重启时按下 Command + R 组合键，进入 macOS 恢复模式，在屏幕上方的菜单中选择 Utlities > Terminal 打开终端，输入并执行：

```
csrutil disable
```

然后重启系统。进行下面的步骤。如果需要启用 SIP，按照以上步骤进入恢复模式，输入并执行 csrutil enable

## 3. 关闭系统目录写保护 (macOS 10.15)

macOS 10.15 Cataline 开始系统目录默认为只读模式，禁用 SIP 以后，仍需开放文件系统写入权限。

在终端中输入并执行：

```
sudo mount -uw /
```

-u 选项表示修改已挂在文件系统的模式，-w选项表示将模式改为可读写 (read-write)，/为根目录即系统挂载点。

## 4. 获得显示器信息

获得显示器的 VendorID 和 ProductID （制造商ID 和 产品ID），在终端运行：

```
ioreg -lw0 | grep IODisplayPrefsKey | grep -o '/[^/]\+"$'
```

输出大概是这样的：

```
> ioreg -lw0 | grep IODisplayPrefsKey | grep -o '/[^/]\+"$'
/AppleBacklightDisplay-610-a029"
/AppleDisplay-10ac-a0de"
```

这条指令的输出会有多个，注意识别你想要调整的显示器。第一条AppleBacklightDisplay-610-a029是MBP的内置显示屏。第二个是外接显示器。（当然，也可以合上 MBP 屏幕，这样只会输出正在使用的外接显示器）

关注AppleDisplay-**-**，-分隔了两个十六进制数。第一个为VendorID，第二个为ProductID。以我的环境为例：VendorID为10ac，ProductID为a0de

## 5. 制作配置

水果的 plist 是 xml 变体，你可以手动写配置文件，也可以用文末的一键生成器。

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>DisplayProductID</key>
    <integer> **** </integer>       <!-- ProductID的 十进制 形式 -->
    <key>DisplayVendorID</key>
    <integer> **** </integer>       <!-- VendorID的 十进制 形式 -->
    <key>scale-resolutions</key>
    <array>
        <data> **def-1** </data>    <!-- HiDPI定义1 -->
        <data> **def-2** </data>    <!-- HiDPI定义2 -->
    </array>
</dict>
</plist>
```

要创建HiDPI分辨率，在scale-resolutions中增加两个<data>项，分别为希望得到的分辨率和缩放分辨率。例如，我想要创建1920x1080的HiDPI设置，def-1对应1920x1080，def-2对应3840x2160。

<data>内部的base64编码后的4个UInt32BE（大端存储的32位无符号整数），格式如下：

UInt32	UInt32	UInt32	UInt32
宽度	高度	Flag	Flag
十进制	1920	1080
十六进制	00 00 07 80	00 00 04 38	00 00 00 01	00 20 00 00

我们需要修改的是宽度和高度，Flag部分不要改动。

把上面这串二进制数进行Base64编码，可以得到：AAAHgAAABDgAAAABACAAAA==和AAAPAAAACHAAAAABACAAAA==。把这个字符串填到对应的<data>标签内。

## 6. 拷贝配置到系统目录

```
# OS X 10.11及以上
DIR=/System/Library/Displays/Contents/Resources/Overrides
# OS X 10.10及以下
DIR=/System/Library/Displays/Overrides

# ${VendorID} 和 ${ProductID} 为上面获得的 VendorID 和 ProductID
# 比如 P2416D，下面两行分别是：VID=10ac 和 PID=a0c4
VID=${VendorID}
PID=${ProductID}

CONF=${DIR}/DisplayVendorID-${VID}/DisplayProductID-${PID}

sudo mkdir -p $( dirname ${CONF} )

# 以下面生成的 P2416D 配置，下载到用户(wacky)的下载文件夹，下面一行是：
# sudo cp /Users/wacky/Downloads/DisplayProductID-a0c4 ${CONF}
sudo cp <配置文件路径> ${CONF}
sudo chown root:wheel ${CONF}
```

## 7. 安装rdm

安装包位置 http://avi.alkalay.net/software/RDM/

## 8. 重启！用RDM切换分辨率

重启后运行 RDM，在任务栏中找到 RDM 的图标，单击打开分辨率选单。带有⚡️标识的为 HiDPI 分辨率。

## 8. 存在的问题

用本文的方式开启 HiDPI，合上 Mac 屏幕，外接显示器黑屏。将外接显示器分辨率切换到屏幕原始分辨率后可以正常地仅使用外接显示器，原因未知。因对我的工作方式没有影响，没有继续研究下去。

系统大版本更新后（如 High Sierra 到 Mojave），需要重新拷贝配置文件。

## 9. 附: Dell U3417W配置

```
# cat Downloads/DisplayProductID-a0de
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<!-- Generated Using: https://wacky.one/blog/macos-hi-dpi/ -->
<!-- By wacky6 -->
<plist version="1.0">
<dict>
    <key>DisplayVendorID</key>
    <integer>4268</integer>
    <key>DisplayProductID</key>
    <integer>41182</integer>
    <key>scale-resolutions</key>
    <array>
        <data>AAAGuAAAAtAAAAABACAAAA==</data>    <!-- 1720x720 -->
        <data>AAANcAAABaAAAAABACAAAA==</data>
        <data>AAANcAAABaAAAAABACAAAA==</data>    <!-- 3440x1440 -->
        <data>AAAa4AAAC0AAAAABACAAAA==</data>
        <data>AAALbAAABMgAAAABACAAAA==</data>    <!-- 2924x1224 -->
        <data>AAAW2AAACZAAAAABACAAAA==</data>
        <data>AAAW2AAACZAAAAABACAAAA==</data>    <!-- 5848x2448 -->
        <data>AAAtsAAAEyAAAAABACAAAA==</data>
        <data>AAAI9QAAA8AAAAABACAAAA==</data>    <!-- 2293x960 -->
        <data>AAAR6gAAB4AAAAABACAAAA==</data>
        <data>AAAR6gAAB4AAAAABACAAAA==</data>    <!-- 4586x1920 -->
        <data>AAAj1AAADwAAAAABACAAAA==</data>
    </array>
</dict>
</plist>

# sudo cp ~/Downloads/DisplayProductID-a0de /System/Library/Displays/Contents/Resources/Overrides/DisplayVendorID-10ac/
```

# Parallels Desktop

迁移vmware格式虚拟机到Parallels格式

首先登录虚拟机，卸载vmware tools，正常关机。取消split disk选项。然后在parallels中打开vmx镜像即可自动识别转换。具体可参考https://www.parallels.com/blogs/convert-vmware-to-parallels/

如果通过上述步骤转换失败，提示如下"This VMware Fusion virtual machine cannot be converted to the Parallels format because it is running"。

则可以通过命令行方式进行转换，步骤如下

```
/Applications/Parallels\ Desktop.app/Contents/MacOS/prl_convert <OS_X>\windows_10_10.vmwarevm/Virtual\ Disk.vmdk --force --no-src-check --no-reconfig --allow-no-os
```

命令行执行成功后，会直接生成pvm格式的parallels镜像，直接打开即可。





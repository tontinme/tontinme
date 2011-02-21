#!/bin/bash

echo "Please run as root:"
echo "请确认已经将当前终端更改为utf8编码(如果你能看到这一行的话就没问题)"
echo "Make sure your Terminal's character encoding is UTF-8"
echo "Pleae give your name(spell) below:"
echo "(no Chinese)"
read hardinfo
if [ -d $hardinfo ]; then
	echo "Directory '$hardinfo' already exists,please use a different name!"
	exit
fi
mkdir $hardinfo
cd $hardinfo
for i in 0 1 2 3 4 7 8 9 16 17
do
        echo $i
        dmidecode -t $i > $i.txt
        if [ $? != '0' ]; then
                exit;
        fi
done
/sbin/ifconfig > ip.txt
if [ $? != '0' ]; then
        exit;
fi
lshw -short > lshw1.txt
if [ $? != '0' ]; then
        exit;
fi
lshw -class disk -short > lshw2.txt
if [ $? != '0' ]; then
        exit;
fi
echo "生成readme信息(N/y)？："
read readme
if [ $readme == 'y' | $readme == 'Y' ]; then
	echo "Give more information below:" > readme.txt
	echo "1.Name(请使用拼音):" >> readme.txt
	echo "2.Location(比如：4007-2，guigu-9,分别表示4007二楼，硅谷九楼):" >> readme.txt
	echo "3.(1-台式机/2-笔记本)(填入序号即可):" >> readme.txt
	echo "4.(1-Ubuntu8.04/2-Ubuntu10.04/3-other)(填入序号即可):" >> readme.txt
	echo "5.(1-日常用机/2-测试用机/3-备用机/4-其他用途)(填入序号即可):" >> readme.txt
	echo "6.其他你认为需要提供的信息(没有请留空):" >> readme.txt
	echo -e "\n\n#Use ":wq" to exit!" >> readme.txt
	vim readme.txt
fi
cd ..
tar zcvf $hardinfo.tar.gz $hardinfo
echo ""
if [ $? == '0' ]; then
	echo "硬件信息已成功打包!"
fi
echo ""
echo "是否将生成的$hardinfo.tar.gz上传至ftp下的/jh/20110218/目录（n/Y）?:"
read upload
if [ $upload != 'y' | $upload != 'Y' ]; then
	echo "You can upload manually!"
	exit
fi
echo "请选择您的网络类型："
echo -e "1).LiShuiQiao   2).Other  (Choose number):\n"
read networktype
if [ $networktype == '1' ]; then
	ftp -n<<!
	open 192.168.1.197
	user proftp pr0ftpo1
	cd jh/20110218
	put $hardinfo.tar.gz
	close
	bye
fi
elif [ $networktype == '2' ]; then
	ftp -n<<!
	open o1.mzhen.cn 2100
	user proftp pr0ftpo1
	cd jh/20110218
	put $hardinfo.tar.gz
	close
	bye
fi
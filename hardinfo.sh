#!/bin/bash

mkdir $1_hardinfo
cd $1_hardinfo
for i in 0 1 2 3 4 7 8 9 16 17
do
        echo $i
        dmidecode -t $i > $i.txt
done
/sbin/ifconfig > ip.txt
lshw -short > lshw1.txt
lshw -class disk -short > lshw2.txt

echo "Give more information below:\n(owner,location,os)";
while true
do
        read infor;
        if [ $infor = "done" ]
        then
                break;
        else
                echo "$infor" >> readme.txt;
        fi
done
cd ..
scp -r $1_hardinfo supertool@192.168.1.81:/home/supertool/i/

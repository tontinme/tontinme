#!/bin/sh
#
#监控MySQL复制是否运行，并且根据具体的错误代码自动判断是否忽略
#

now=`date + "%Y%m%d%H%M%S"`
statFile="./slave_status.$now"
echo "show slave status\G" | mysql -uroot > $statFile

ioStat=`cat $statFile | grep Slave_IO_Running | awk '{print $2}'`
sqlStat=`cat $statFile | grep Slave_SQL_Running | awk '{print $2}'`
errno=`cat $statFile | grep Last_Errno | awk '{print $2}'`

#ioStat=`cat $statFile | head -n 12 | tail -n 1 | awk '{print $2}'`
#sqlStat=`cat $statFile | head -n 13 | tail -n 1 | awk '{print $2}'`
#errno=`cat $statFile | head -n 20 | tail -n 1 | awk '{print $2}'`

if [ $ioStat = 'No' ] || [$sqlStat = 'No' ]; then
	echo "chkslave"
	date
	#如果错误代码为0，则可能是因为网络等原因导致复制中断，直接重启复制即可
	if [ "$errno" -eq 0 ]; then
		echo "start slave io_thread; start slave sql_thread;" | mysql -uroot
		echo "start slave io_thread; start slave sql_thread;"
	#如果是一些不是很要紧的错误代码，也可以直接略过
	elif [ "$errno" -eq 1007 ] || [ "$errno" -eq 1053 ] || [ "$errno" -eq 1062 ] || [ "$errno" -eq 1213 ]\
	       	|| [ "$errno" -eq 1158 ] || [ "$errno" -eq 1159 ] || [ "$errno" -eq 1008 ]; then
		echo "stop slave; set global sql_slave_skip_counter=1; slave start;" | mysql -uroot
		echo "stop slave; set global sql_slave_skip_counter=1; slave start;"
	else
		echo `date` "slave is donw!!!"
	fi

	#删除临时状态文件
	rm -f $statFile
	echo "[/chkslave]"
fi

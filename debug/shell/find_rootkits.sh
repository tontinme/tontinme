#!/bin/bash

str_pids=`ps -A | awk '{print $1}'`

for i in /proc/[0-9]*;
do
	if echo $str_pids | grep -q `basename $i`;
	then
		:
	else
		echo "Rootkit's PID:`basename $i`" >> ./Rootkits.log
	fi
done
unset str_pids i

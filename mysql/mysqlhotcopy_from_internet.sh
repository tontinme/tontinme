#!/bin/bash
DATE = `date + %y%m%d.%H`
DATADIR = "/data0/mysql/data"
BACKDIR_DAILY= = "/data0/local/mysqld/daily"
BACKDIR_HOURLY = "/data0/local/mysqld/hourly"
INTERVAL = "$1"
TMPDIR = "/var/tmp/"
TMPDIRH = "$TMPDIR"hourly
TMPDIRD = "$TMPDIR"daily
LOGDIR = "/data0/log/dbbackup/"
KEEPH_LOCAL = 1
USER = hotcopy
PASSWD = hotcopy
KEEPH_NFS = 7
KEEPD_LOCAL = 3
KEEPD_NFS = 14
HOST = `hostname -s`
MYVERSION = "5.1"

mkdir -p $LOGDIR
case $INTERVAL in
	hourly | HOURLY | Hourly | 1 )
		echo "" && echo"~~~~~~~~~~~~~~~~~~~~"
		echo "Performing HOURLY level backup - `date + $m-$d.%H:%M:%S`" &&echo ""
		echo "" &&echo "~~~~~~~~~~~~~~~~~~~~" >> "$LOGDIR"hourly.log
		echo "Performing HOURLY level backup - `date + $m-$d.%H:%M:%S`" >> "$LOGDI"hourly.log
		mkdir -p $TMPDIRH
		mkdir -p $BACKDIR_HOURLY
		/usr/local/mysql/bin/mysqlhotcopy --allowold test -u $USER -p $PASSWD $TMPDIRH > /dev/null
		echo "" &&echo "" && echo "~~~~~~~~~~~~~~~~~~~~~~"
		echo "Compressing - `date + $m-$d.%H:%M:%S`"
		echo "Compressing - `date + $m-$d.%H:%M:%S`" >> "$LOGDIR"hourly.log
		cd $TMPDIRH
		find . -maxdepth 1 -type d -user mysql -exec tar czf {}-"$DATE".tar.gz '{}' \;

		echo ""
		echo "Copying local... - `date + $m-$d.%H:%M:%S`"
		echo "Copying local... - `date + $m-$d.%H:%M:%S`" >> "$LOGDIR"hourly.log
		cd $TMPDIRH
		chattr -i $BACKDIR_HOURLY
		find $BACKDIR_HOURLY -type f -mtime +7 -exec rm {} \;
		mv * $BACKDIR_HOURLY
		chattr +i $BACKDIR_HOURLY

		echo ""
		echo "Ending - `date + $m-$d.%H:%M:%S`" >> "$LOGDIR"hourly.log

		exit 0
		;;
	daily | DAILY | Daily | 2 )
		echo "" && echo"~~~~~~~~~~~~~~~~~~~~"
		echo "Performing DAILY level backup - `date + $m-$d.%H:%M:%S`" &&echo ""
		echo "" &&echo "~~~~~~~~~~~~~~~~~~~~" >> "$LOGDIR"daily.log
		echo "Performing DAILY level backup - `date + $m-$d.%H:%M:%S`" >> "$LOGDI"daily.log
		mkdir -p $TMPDIRH
		mkdir -p $BACKDIR_DAILY
		/usr/local/mysql/bin/mysqlhotcopy --allowold test -u $USER -p $PASSWD $TMPDIRH > /dev/null
		echo "" &&echo "" && echo "~~~~~~~~~~~~~~~~~~~~~~"
		echo "Compressing - `date + $m-$d.%H:%M:%S`"
		echo "Compressing - `date + $m-$d.%H:%M:%S`" >> "$LOGDIR"daily.log
		cd $TMPDIRH
		find . -maxdepth 1 -type d -user mysql -exec tar czf {}-"$DATE".tar.gz '{}' \;

		echo ""
		echo "Copying local... - `date + $m-$d.%H:%M:%S`"
		echo "Copying local... - `date + $m-$d.%H:%M:%S`" >> "$LOGDIR"daily.log
		cd $TMPDIRH
		chattr -i $BACKDIR_DAILY
		find $BACKDIR_DAILY -type f -mtime +7 -exec rm {} \;
		mv * $BACKDIR_DAILY
		chattr +i $BACKDIR_DAILY

		echo ""
		echo "Ending - `date + $m-$d.%H:%M:%S`" >> "$LOGDIR"daily.log

		exit 0
		;;
	*)
		echo ""
		echo "~~~~~~~~~~~~~~~~~~~~"
		echo "Invalid Selection" 1>&2
		exit 1
esac

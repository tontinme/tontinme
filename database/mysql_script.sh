#!/bin/sh

#MySQL备份脚本
	###################################################################
	#######mysqldump###################################################
	#!/bin/sh
	# mysql_backup.sh: backup mysql databases and keep newest 5 days backup.
	# -----------------------------
	db_user="root"
	db_passwd="linuxtone"
	db_host="localhost"

	# the directory for story your backup file.
	backup_dir="/backup"

	# date format for backup file (dd-mm-yyyy)
	time="$(date +"%d-%m-%Y")"

	# mysql, mysqldump and some other bin's path
	MYSQL="$(which mysql)"
	MYSQLDUMP="$(which mysqldump)"
	MKDIR="$(which mkdir)"
	RM="$(which rm)"
	MV="$(which mv)"
	GZIP="$(which gzip)"

	#针对不同系统，如果环境变量都有。可以去掉

	# check the directory for store backup is writeable
	test ! -w $backup_dir && echo "Error: $backup_dir is un-writeable." && exit 0

	# the directory for story the newest backup
	test ! -d "$backup_dir" && $MKDIR "$backup_dir"

	# get all databases

	for db in cdn cdn_view
	do
       		$MYSQLDUMP -u $db_user -h $db_host -p$db_passwd $db | $GZIP -9 > "$backup_dir/$time.$db.gz"
	done

	#delete the oldest backup 30 days ago
	find $backup_dir -name "*.gz" -mtime +30 |xargs rm -rf

	exit 0;

	###################################################################
	##########带邮件通知的mysqldump#####################################
	#!/bin/sh
	# Name:mysqlFullBackup.sh
	# PS:MySQL DataBase Full Backup.
	# Write by:i.Stone
	# Last Modify:2008-9-17
	#
	# Use mysqldump --help get more detail.
	#
	scriptsDir=`pwd`
	mysqlDir=/usr/local/mysql ?
	user=root
	userPWD=111111
	dataBackupDir=/tmp/mysqlbackup
	eMailFile=$dataBackupDir/email.txt
	eMail=liuyu@sohu.com
	logFile=$dataBackupDir/mysqlbackup.log
	DATE=`date -I`
	
	echo "" > $eMailFile
	echo $(date +"%y-%m-%d %H:%M:%S") >> $eMailFile
	cd $dataBackupDir
	dumpFile=mysql_$DATE.sql
	GZDumpFile=mysql_$DATE.sql.tar.gz

	$mysqlDir/bin/mysqldump -u$user -p$userPWD \
	--opt --default-character-set=utf8 --extended-insert=false \
	--triggers -R --hex-blob --all-databases \
	--flush-logs --delete-master-logs \
	--delete-master-logs \
	-x > $dumpFile

	if [[ $? == 0 ]]; then
		tar czf $GZDumpFile $dumpFile >> $eMailFile 2>&1
		echo "BackupFileName:$GZDumpFile" >> $eMailFile
		echo "DataBase Backup Success!" >> $eMailFile
		rm -f $dumpFile

		# Delete daily backup files.
		cd $dataBackupDir/daily
		rm -f *

		# Delete old backup files(mtime>2).
		$scriptsDir/rmBackup.sh

		# Move Backup Files To Backup Server.
		$scriptsDir/rsyncBackup.sh
		if (( !$? )); then
			echo "Move Backup Files To Backup Server Success!" >> $eMailFile
		else
			echo "Move Backup Files To Backup Server Fail!" >> $eMailFile
		fi

	else
		echo "DataBase Backup Fail!" >> $emailFile
	fi

	echo "--------------------------------------------------------" >> $logFile
	cat $eMailFile >> $logFile
	cat $eMailFile | mail -s "MySQL Backup" $eMail


	###################################################################
	############### tar ###############################################
	#!/bin/bash
	#15 3 * * * /usr/local/sbin/backup.sh
	#backup directory
	BAK_DIR=/data/db_backup

	TAR="/bin/tar"
	TAR_FLAG="czvf"
	#BAKup
	if [ ! -d $BAK_DIR ];then
		mkdir -p $BAK_DIR
	fi

	COMM="$TAR $TAR_FLAG $BAK_DIR/linuxtone-`date +%Y%m%d`.tar.gz linuxtone/"
	cd /data/mysql/data
	eval $COMM

	find $BAK_DIR -name "linuxtone-*.tar.gz" -mtime +30 |xargs rm -rf

	###################################################################
	###################mysqlhotcopy####################################
	#!/bin/sh
	DBS=`du /var/lib/mysql/linuxtone/ | awk '{ printf $1 }'`
	DFS=`df /myhotco | grep myhotco | awk '{ printf $3}'`
	let "DBS = $DBS / 1024"
	let "DFS = $DFS / 1024"
	# more than 100M free space up
	if [ `expr $DBS + 100` -lt $DFS ] ; then
		echo "run mysqlhotcopy ( `expr $DFS - $DBS` ) ..."
		/usr/bin/mysqlhotcopy linuxtone --allowold --flushlog /myhotco
	fi

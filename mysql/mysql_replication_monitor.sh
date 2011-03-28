#!/bin/bash
#mysql_replication_monitor.sh - a mysql replication monitor

DB_USER=root
DB_PASS=""

alert_to=""
alert_cc=""
alert_failed_subject="REPLICATION FAILED"
alert_failed_message="one of the replication threads on the slave server failed or the server is down\n"
alert_slow_subject="REPLICATION SLOW"
alert_slow_message="the slave is behind by"

lockfile=/tmp/replication_monitor.lock
rf=$(mktemp)

echo "show slave status\G" | /usr/local/mysql/bin/mysql -u $DB_USER -password=$DB_PASS > $rf 2>&1

repl_IO=$(cat $rf | grep "Slave_IO_Running" | cut -f2 -d ':')
repl_SQL=$(cat $rf | grep "Slave_SQL_Running" | cut -f2 -d ':')
repl_BEHIND=$(cat $rf | grep "Seconds_Behind_Master" | cut -f2 -d ':')

if [ ! -e $lockfile ]; then
	#alert down
	if [ "$repl_IO" != "Yes" -o "$repl_SQL" != "Yes" ]; then
		if [ "$alert_cc" != "" ]; then
			cc="-c $alert_cc"
		fi
		cat <<EOF | mail -s "$alert_failed_subject" $alert_to $cc
		$alert_failed_message
		return from slave status command:
		$(cat $rf)
EOF
		rm $rf
	fi
	#alert slow
	if [ $repl_BEHIND -ge 30 ]; then
		if [ "$alert_cc" != "" ]; then
			cc="-c $alert_cc"
		fi
		cat <<EOF | mail -s "$alert_slow_subject" $alert_to $cc
		$alert_slow_message $repl_BEHIND seconds
EOF
	fi
	touch $lockfile
fi

#!/bin/bash
# put this script in root crontab
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
logname='Sleep-Watchdog.log'
timestamp=`date '+%Y.%m.%d %H:%M:%S'`
get_percent () {
	pmset -g batt|grep InternalBattery|awk '{print $3}'|sed s/%.*//
}
set_threshold () {
	# note: add test for numeric value and conver float to integer!
	if test -z $1; then
		threshold='10'
	else
		threshold=$1
	fi
	echo $threshold
}
set_log () {
	log=$1/$logname.$(date '+%Y%m%d')
	find $1 -name "$logname.*" -mtime +5 -delete
	ln -sf $log $1/$logname
}
set_log /var/log
kill_pid () {
	pid=`pgrep $1`
	if test -z $pid; then
		echo "$timestamp $1 not running" >> $log
	else
		kill $pid
		retval_kill=$?
		echo "$timestamp $1 was killed, retval_kill = $retval_kill" >> $log
	fi
}
unload_kext () {
	if `kextstat |grep $1 &> /dev/null`; then
		kextunload -b $1
		retval_kextunload=$?
		echo "$timestamp kext $1, retval_kextunload = $retval_kextunload" >> $log
	else
		echo "$timestamp kext $1 not loaded" >> $log
	fi
}

threshold=`set_threshold $1`
current=`get_percent`

if test $current -ge $threshold; then
	echo "$timestamp battery current = $current is greater than $threshold" >> $log
else
	echo "$timestamp battery current = $current is less then $threshold" >> $log
	if pmset -g batt|grep discharging &> /dev/null; then
		kill_pid InsomniaX
		unload_kext net.semaja2.kext.insomnia
		kill_pid SleepLess
		unload_kext org.binaervarianz.driver.insomnia
	fi
fi

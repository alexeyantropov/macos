#!/bin/bash
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
logname='InsomniaX-Watchdog'
timestamp=`date '+%Y.%m.%d %H:%M:%S'`
get_percent () {
	pmset -g batt|grep InternalBattery|awk '{print $2}'|sed s/%.*//
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
}

threshold=`set_threshold $1`
current=`get_percent`
set_log /var/tmp

if test $current -ge $threshold; then
	# just log battery state 
	echo "$timestamp battery current = $current is greater than $threshold" >> $log
else
	# unload InsomniaX
	echo "$timestamp battery current = $current is less then $threshold" >> $log
	pid=`pgrep InsomniaX`
	if test -z $pid; then
		echo "$timestamp InsomniaX not running" >> $log
	else
		kill $pid
		retval_kill=$?
		echo "$timestamp InsomniaX was killed, retval_kill = $retval_kill" >> $log
	fi
	if `kextstat |grep net.semaja2.kext.insomnia &> /dev/null`; then
		kextunload -b net.semaja2.kext.insomnia
		retval_kextunload=$?
		echo "$timestamp kext net.semaja2.kext.insomnia unloaded, retval_kextunload = $retval_kextunload" >> $log
	else
		echo "$timestamp kext net.semaja2.kext.insomnia not loaded" >> $log
	fi
fi

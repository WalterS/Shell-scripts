#!/bin/bash

############################################################
# shutdown.sh
#
# Shuts machine down only if $process is not running
# Checks every $wait_time minutes/seconds
#
# Needs /usr/local/bin/stopvms and /usr/local/bin/netio_wd
#
# WS 20091211
############################################################
########## Changes ##########
####
# Added script for Netio
# WS 20110316
####
# Added script for VMs
# WS 20110331
####
# sh -> bash, footer at the end of log file
# WS 20110410
####

########### Configure here ###########
process=BackupPC_dump
wait_time=5m
log=/tmp/`basename $0`.log
######### Configuration end ##########

start_time=`date '+%s'`
counter=0
end_time=
exec_time=0
is_running=1
prc=


# Check if log file is accessible
if touch $log; then
	:
else
	echo "Could not access log file $log"
	exit 1
fi

# Check periodically if process is running
while [ $is_running -eq 1 ]; do
	prc=`/usr/local/bin/psgrep "${process}" | awk '!/BackupPC -d/ && ! /BackupPC_trashClean/'`
	if [ "$prc" == "" ]; then
		is_running=0
	else
		counter=`expr $counter + 1`
		/bin/sleep $wait_time
	fi
done

# Compute run time
end_time=`date '+%s'`

if [ $counter -gt 0 ]; then
	exec_time=$(($(($end_time-$start_time))/60))
fi


# Shut down VMs
echo "Shutting down VMs" >> $log
/usr/local/bin/stopvms &>> $log

# Turn off watchdog on NETIO
echo "Turning off watchdog on NETIO" >> $log
/usr/local/bin/netio_wd off &>> $log

# Write log file footer
cat << END >> $log
Shutting down machine after $counter waiting cycle(s) ($exec_time minutes).
`date '+%Y%m%d %H:%M'`
_____________________________________________________________________________________

END

# Shut down machine
/sbin/poweroff

# EOF

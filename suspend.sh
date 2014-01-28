#!/bin/bash

############################################################
# suspend.sh
#
# Suspend machine only if $PROCESS is not running
# Checks every $WAIT_TIME minutes/seconds
#
# WS 20091211
############################################################
########## Changes ##########
# Errors are printed to stderr now
# WS 20110408
####
# sh -> bash, internal arithmetics
# WS 20110411
####

PROCESS=BackupPC_dump
WAIT_TIME=5m
LOG=/tmp/${0##*/}.log

START_TIME=$(date '+%s')
COUNTER=0
END_TIME=0
EXEC_TIME=0
IS_RUNNING=0
PRC=


# Check if log file is accessible
if ! touch $LOG > /dev/null 2>&1; then
	echo "Could not access log file $LOG" >&2
	exit 1
fi

# Check periodically if process is running
PROCESS=$(sed 's/[[:alnum:]]/[&]/'<<<$PROCESS)
while [[ $IS_RUNNING = 0 ]]; do
	PRC=$(ps -ef | awk '/'$PROCESS'/ && (!/BackupPC -d/ && ! /BackupPC_trashClean/)')
	if [[ -z "$PRC" ]]; then
		IS_RUNNING=1
	else
		((COUNTER++))
		sleep $WAIT_TIME
	fi
done

# Compute run time
END_TIME=$(date '+%s')

if [[ $COUNTER -gt 0 ]]; then
	EXEC_TIME=$[$[END_TIME - START_TIME]/60]
fi

# Write log file
cat << END >> $LOG
_____________________________________________________________________________________
$(date '+%Y%m%d %H:%M')
Suspending machine after $COUNTER wait cycles ($EXEC_TIME minutes).

END

# Suspend machine
netio_wd off &
/usr/lib/systemd/systemd-sleep suspend &

# EOF

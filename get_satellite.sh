#!/bin/bash

############################################################
# get_satellite.sh
#
# Fetches the most current satellite image from yr.no
#
# WS 20091103
############################################################
########## Changes ##########
####
# Cosmetic changes
# WS 20110407
####


########### Configure here ###########
# Where to store the image
dir=/home/walter/doc/weather
# Base name, picture will be ${dir}/${name}.jpg and log file
# ${dir}/${name}.log
name=satellite

# Website to use for scraping
site=http://www.yr.no/satellitt/1.5941755

# Search strings for scraping
# Make sure to escape all <>.?/ etc.
search_str1='\<img src="http:\/\/api.yr.no\/weatherapi\/geosatellite\/1\.3\/\?area=europe'
search_str2='width=650'

# Which record (first=0)?
occurrence=0

# Debug switch
debug=0
######### Configuration end ##########

rc=0

# Some basic tests
if [ -d $dir ] &> /dev/null; then
	:
else
	mkdir -p $dir
	if [ $? -ne 0 ]; then
		echo Directory $dir is not available
		((rc++))
		exit $rc
	fi
fi

log=${dir}/${name}.log

if touch $log &> /dev/null; then
	:
else
	echo Log file $log is not accessible
	((rc++))
	exit $rc
fi

############################################################
#### Here we go

# Function for clean exit
cleanup () {
rm -f ${dir}/${name}1.jpg &> /dev/null
exit $rc
}

# We want to exit cleanly
trap 'cleanup' 0
trap 'echo "Program aborted"; exit 3' 1 2 3 15

# Header for log file
header () {
cat << END
____________________________________________________________
`date '+%Y%m%d %H:%M:%S'`
END
}

# Function for grabbing the image
getimage () {

if wget -o $log -O ${dir}/${name}1.jpg $location; then
	if [ $debug -eq 1 ]; then
		cat << END >> $log
`header`

DEBUG: Downloaded image from $location

END
	fi
else
	cat << END >> $log
`header`

ERROR: Could not download satellite image
URL: $location
END
	((rc++))
	cleanup
fi

if [ $? -eq 0 -a -s ${dir}/${name}1.jpg ]; then
	mv -f ${dir}/${name}1.jpg ${dir}/${name}.jpg 
fi

}

# Get URL
location=`wget -qO - $site | awk -F\" '(/'"$search_str1"'/ && /'"$search_str2"'/) && s=='"$occurrence"' {print $2; s++1}'`

if [ "$location" == "" ]; then
	cat << END >> $log
`header`

ERROR: Could not get URL for satellite image
END
	((rc++))
	cleanup
fi

# Test whether picture has changed
timestamp=`echo $location | awk -F'=|;|' '{print $(NF-3)}'`

if [ "$timestamp" == "" ]; then
	cat << END >> $log
`header`

ERROR: Could not extract timestamp from URL for comparison
END
	((rc++))
	cleanup
fi

# Download only if picture has changed and when there is no error in log file
if grep $timestamp $log &> /dev/null; then
	if grep -E 'ERROR|failed' $log &> /dev/null; then
		getimage
	else
		if [ $debug -eq 1 ]; then
		cat << END >> $log
`header`

DEBUG: Link to image has not changed ($timestamp)
END
		fi
	fi
else
	getimage
fi

cleanup

exit 99

# EOF

#!/bin/bash

############################################################
# get_satellite.sh
#
# Fetches the most current satellite image from yr.no
#
# WS 20091103
############################################################

########### Configure here ###########
# Where to store the image
DIR=/home/walter/doc/weather
# Base name, picture will be ${DIR}/${NAME}.png and log file
# ${DIR}/${NAME}.log
NAME=satellite

# Website(s) to use for scraping
SITES="http://www.yr.no/satellitt/europa.html http://www.yr.no/satellitt/europa_dag_natt.html"

# Search strings for scraping
# Make sure to escape all <>.?/ etc.
SEARCH_STR1='="http:.*\/weatherapi\/geosatellite\/1\.[0-9]\?area=europe'
SEARCH_STR2='size=normal'

# Which record (first=0)?
OCCURRENCE=0

# Debug switch
DEBUG=0
######### Configuration end ##########

# We want to exit cleanly
trap 'rm -f ${DIR}/${NAME}1.png &> /dev/null' 0
trap 'echo "Program aborted"; exit 3' 1 2 3 15

RC=0

# Some basic tests
if ! [[ -d "$DIR" ]] &> /dev/null; then
	mkdir -p "$DIR"
	if ! [[ -d "$DIR" ]] &> /dev/null; then
		echo "Error: Directory $DIR is not available" >&2
		((RC++))
		exit $RC
	fi
fi

# Header for log file
header () {
cat << END
____________________________________________________________
$(date '+%Y%m%d %H:%M:%S')
END
}

# Function for grabbing the image
getimage () {

if wget -o "$LOG" -O ${DIR}/${NAME}1.png $LOCATION; then
	if [[ $DEBUG = 1 ]]; then
		cat << END >> "$LOG"
$(header)

Debug: Downloaded image from $LOCATION

END
	fi
else
	cat << END >> "$LOG"
$(header)

Error: Could not download satellite image
URL: $LOCATION
END
	((RC++))
	exit 1
fi

if [[ $? = 0 && -s ${DIR}/${NAME}1.png ]]; then
	touch -d "$(date -d @$(date -ud "$(sed 's/time=\|;//g;s/%3A/:/g;s/T\|Z/ /g'<<<$TIMESTAMP)" +'%s') '+%Y-%m-%d %H:%M:%S')" ${DIR}/${NAME}1.png
	exiftool -q -m -P "-DateTimeOriginal<FileModifyDate" -overwrite_original ${DIR}/${NAME}1.png
	mv -f ${DIR}/${NAME}1.png ${DIR}/${NAME}.png &>/dev/null
fi
}

for SITE in $SITES; do
	QUALIFIER=$(awk -F'[./]' '{print $(NF-1)}'<<<$SITE)
	LOG=${DIR}/${NAME}_${QUALIFIER}.log
	NAME=${NAME}_${QUALIFIER}

	if ! touch "$LOG" &> /dev/null; then
		echo "Error: Log file $LOG is not accessible" >&2
		((RC++))
		exit $RC
	fi

	############################################################
	#### Here we go

	# Get URL
	LOCATION=$(wget -qO - $SITE | awk -F\" '(/'"$SEARCH_STR1"'/ && /'"$SEARCH_STR2"'/) && s=='"$OCCURRENCE"' {print $2; s++1}' 2>/dev/null)

	if [[ -z "$LOCATION" ]]; then
		cat << END >> "$LOG"
$(header)

Error: Could not get URL for satellite image
END
		((RC++))
		exit 1
	fi

	# awk -F'=|;|' '{gsub("%3A",":");print $6}' <<<$LOCATION
	# Test whether picture has changed
	if [[ $DEBUG = 1 ]]; then
		cat <<- END >> "$LOG"
			$(header)

			Debug: Raw time stamp: $LOCATION

		END
	fi

	if ! TIMESTAMP=$(awk -F'=|;|' '{print $6}' <<<$LOCATION); then
		TIMESTAMP_=$TIMESTAMP
		TIMESTAMP=
	fi

	if [[ -z "$TIMESTAMP" ]]; then
		cat << END >> "$LOG"
$(header)

Error: Could not extract timestamp from URL for comparison ($TIMESTAMP_)
END
		((RC++))
		exit 1
	fi

	# Download only if picture has changed and when there is no error in log file
	if grep -q $TIMESTAMP "$LOG"; then
		if egrep -q 'Error|failed' "$LOG"; then
			getimage
		else
			if [[ $DEBUG = 1 ]]; then
				cat << END >> "$LOG"
$(header)

Debug: Link to image has not changed ($TIMESTAMP)
END
			fi
		fi
	else
		getimage
	fi
done

exit 0

# EOF

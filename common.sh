#
# This file can be safely removed.
#
# This is a work in progress, and may include bugs.  Use at your own risk.
#
### Common Variables
HOST=`hostname | cut -d. -f1`
PREFERRED_DATE_FORMAT="%Y/%m/%d %H:%M:%S"
#####################

pathmunge () {
	if ! echo $PATH | /bin/egrep -q "(^|:)$1($|:)" ; then
	   if [ "$2" = "before" ] ; then
	      PATH=$1:$PATH
	   else
	      PATH=$PATH:$1
	   fi
	fi
}

# Path manipulation
pathmunge /usr/local/sbin
pathmunge /usr/local/bin
pathmunge ~/bin

# Aliases galore:
alias Grep='grep '
alias df='df -h'
alias du='du -h'
alias ROOT='sudo su -'
alias dell_model=`dmidecode | grep -C3 -i dell | grep 'Product Name:' | head -1`

### Common Tasks ######################################################
function match_ip {
	egrep -o '([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})' | grep -v 255
}

function dev_null {
	if [ $# -eq 0 ]; then
		echo 'Runs whatever <cmd> > /dev/null 2>&1&'
		echo "Usage: $0 <cmd>"; 
	else
		$* > /dev/null 2>&1&
	fi
}

### Debug Functions ###################################################
function debug {
	if [ $1 -eq 0 ]; then
		set +o xtrace
		set +o verbose
	else
		set -o xtrace
		set -o verbose
	fi
}

### Time functions ####################################################
function uptime_secs {
	UPSEC=`cat /proc/uptime | cut -d. -f1`
	echo $UPSEC
}
function uptime_mins {
	UPSEC=`cat /proc/uptime | cut -d. -f1`
	UPMIN=$(( $UPSEC / 60 ))
	echo $UPMIN
}
function uptime_hours {
	UPSEC=`cat /proc/uptime | cut -d. -f1`
	UPMIN=$(( $UPSEC / 60 ))
	UPHR=$(( $UPMIN / 60 ))
	echo $UPHR
}
function uptime_days {
	UPSEC=`cat /proc/uptime | cut -d. -f1`
	UPDAY=$(( $UPSEC / 60 / 60 / 24 ))
	echo $UPDAY
}

### Process/Pid Functions #############################################
function proc_start {
	PIDS=`pgrep $1`
	for pid in $PIDS; do
		SYS_START=`cat /proc/uptime | cut -d\  -f1 | cut -d. -f1`
		PROC_START=`cat /proc/$pid/stat | cut -d\  -f22`
		PROC_START=$(( $PROC_START / 100 ))
		PROC_UPTIME=$(( $SYS_START - $PROC_START ))
		PROC_START=`date -d "-${PROC_UPTIME} seconds"`
		echo "$pid : $PROC_START"
	done
}

function proc_age {
	PIDS=`pgrep $1`
	for pid in $PIDS; do
		SYS_START=`cat /proc/uptime | cut -d\  -f1 | cut -d. -f1`
		PROC_START=`cat /proc/$pid/stat | cut -d\  -f22`
		PROC_START=$(( $PROC_START / 100 ))
		UPSEC=$(( $SYS_START - $PROC_START ))
		UPMIN=$(( $UPSEC / 60 ))
		UPHR=$(( $UPSEC / 60 / 60 ))
		UPDAY=$(( $UPSEC / 60 / 60 / 24 ))
		DAYHR=$(( $UPDAY * 24 )); UPHR=$(( $UPHR - $DAYHR ))
		HRMIN=$(( $UPHR * 60 )); UPMIN=$(( $UPMIN - $HRMIN ))
		MINSEC=$(( $UPDAY * 24 * 60 * 60 + $UPHR * 60 * 60 + $UPMIN * 60 )); UPSEC=$(( $UPSEC - $MINSEC ))
		echo "${UPDAY}d, ${UPHR}h, ${UPMIN}m, ${UPSEC}s"
	done
}

function proc_upseconds {
	PIDS=`pgrep $1`
	for pid in $PIDS; do
		SYS_START=`cat /proc/uptime | cut -d\  -f1 | cut -d. -f1`
		PROC_START=`cat /proc/$pid/stat | cut -d\  -f22`
		PROC_START=$(( $PROC_START / 100 ))
		UPSEC=$(( $SYS_START - $PROC_START ))
		echo $UPSEC
	done
}

function pid_start {
	SYS_START=`cat /proc/uptime | cut -d\  -f1 | cut -d. -f1`
	PROC_START=`cat /proc/$1/stat | cut -d\  -f22`
	PROC_START=$(( $PROC_START / 100 ))
	PROC_UPTIME=$(( $SYS_START - $PROC_START ))
	PROC_START=`date -d "-${PROC_UPTIME} seconds"`
	echo "$PROC_START"
}

function pid_age {
	SYS_START=`cat /proc/uptime | cut -d\  -f1 | cut -d. -f1`
	PROC_START=`cat /proc/$1/stat | cut -d\  -f22`
	PROC_START=$(( $PROC_START / 100 ))
	UPSEC=$(( $SYS_START - $PROC_START ))
	UPMIN=$(( $UPSEC / 60 ))
	UPHR=$(( $UPSEC / 60 / 60 ))
	UPDAY=$(( $UPSEC / 60 / 60 / 24 ))
	DAYHR=$(( $UPDAY * 24 )); UPHR=$(( $UPHR - $DAYHR ))
	HRMIN=$(( $UPHR * 60 )); UPMIN=$(( $UPMIN - $HRMIN ))
	MINSEC=$(( $UPDAY * 24 * 60 * 60 + $UPHR * 60 * 60 + $UPMIN * 60 )); UPSEC=$(( $UPSEC - $MINSEC ))
	echo "${UPDAY}d, ${UPHR}h, ${UPMIN}m, ${UPSEC}s"
}

function pid_upseconds {
	SYS_START=`cat /proc/uptime | cut -d\  -f1 | cut -d. -f1`
	PROC_START=`cat /proc/$1/stat | cut -d\  -f22`
	PROC_START=$(( $PROC_START / 100 ))
	UPSEC=$(( $SYS_START - $PROC_START ))
	echo $UPSEC
}

# Does the math to convert 'sar -r' data into a usable percentage.
#
function memory_percentage
{

	TOTAL_MEM=`cat /proc/meminfo | head -1 | awk '{print $2}'`		

	IFS="
"

	for line in `sar -r $@ | grep '[AP]M.*[0-9]'`; do 
		echo -n $line | awk '{printf $1 " " $2 " : "}'
		echo -n $line | awk "{printf \"2 k \" \$4 \" \" \$7 \" - ${TOTAL_MEM} / 100 * p\"}" | dc
		
	done
}


# Converts epoch time to standard time inline.  Will take filenames on the cmd line or text piped in
#  through stdin.  Useful for nagios logs and the like.
#
function s2t
{
	if [ $# -gt 0 ]; then
		echo $1 | egrep '^[0-9]+$' > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			date -d @$1 +"${PREFERRED_DATE_FORMAT}"
		else
			print "Invalid timestamp: $1"
		fi
	else
		while read timestr; do
			TIMES=( `echo $timestr | egrep -o '\b[0-9]+\b' 2> /dev/null` )
			for (( x=0; ${TIMES[$x]}; x++ )); do
				S2T=`date -d @${TIMES[$x]} +"$PREFERRED_DATE_FORMAT" | sed 's/\//\\\\\//g'`
				timestr=`echo $timestr | sed "s/${TIMES[$x]}/$S2T/g"`
			done
			echo $timestr
		done
	fi
}

# Apache hit Counter, with fancy spinning mesmerizer 
#
function ahc	
{
	DEBUG=0

	[ $DEBUG -ge 2 ] && debug 1

	spinner=( '|' '/' '-' '\' )

	VERSION=04.06.2010

	function usage
	{
		echo "ahc v$VERSION by Rev. Dr. Aaron M. Segura"
		echo "Usage: ahc -f <access_log> [-s <startTime>] [-e <endTime>] [-i <interval=60>]"
		echo "Times in format recognized by `which date`.  man date, search for DATE STRING."
	
		[ "$1" ] && echo -e "\n*!* $@ \n"
	}
	
	function cleanup
	{
		END_TIME=`date +%s`
		echo ""
		echo "Caught Signal.  Shutting down..."
		echo "Processed $CTR lines in $(( $END_TIME - $START_TIME )) seconds, $(( $CTR / ( $END_TIME - $START_TIME) )) h/s"
		echo "Done."

		[ -e /proc/$$/fd/250 ] && exec 250>&-		

		trap - SIGKILL SIGTERM SIGUSR1 SIGINT
		unset LOG_FILE LOG_START LOG_END INTERVAL START_TIME END_TIME INT_CTR OPTIND DATA

		break 2
	}
	
	trap cleanup SIGTERM SIGKILL SIGINT SIGUSR1 

	unset OPTIND	
	while getopts ":f:s:e:i:t:" opt; do 
		case $opt in 
			"f")
				if [ ! -r $OPTARG ]; then
					usage "Specified file: \"$OPTARG\" is not a file or is inaccessible" && return
				else
					LOG_FILE=$OPTARG 
				fi
			;;
			"s") 
				LOG_START=`echo $OPTARG | date -d "$OPTARG" +%s 2> /dev/null`
				if [ $? -eq 0 ]; then
					[ $DEBUG -ge 1 ] && echo "Using $LOG_START for starting time expression"
				else
					usage "Invalid Start Time: $OPTARG" && return
				fi
			;;
			"e")
				LOG_END=`echo $OPTARG | date -d "$OPTARG" +%s 2> /dev/null`
				if [ $? -eq 0 ]; then
					[ $DEBUG -ge 1 ] && echo "Using $LOG_END for starting time expression"
				else
					usage "Invalid End Time: $OPTARG" && return
				fi
			;;
			"i")
				echo $OPTARG | egrep '^[0-9]+$' > /dev/null 2>&1
				if [ $? -eq 0 ]; then 
					INTERVAL=$OPTARG	
				else
					usage "Invalid interval specified: $OPTARG" && return
				fi	
			;;
		esac
	done
	
	[ ! "$LOG_FILE"  ] && usage "Must specify an apache access_log file with -f <logfile>" && return
	
	[ -z $LOG_START  ] && LOG_START=0
	[ -z $LOG_END    ] && LOG_END=9999999999  #ONOES!  WE R DED!
	[ -z $INTERVAL   ] && INTERVAL=60
	
	CTR=0
	
	echo -n "Processing $LOG_FILE    "
	
	START_TIME=`date +%s`
	exec 250<$LOG_FILE 
	
	while read -r line <&250 ; do 
		TP=( `echo $line | awk '{print $4}' | tr '[/:' ' '` )	
		LS=`date -d "${TP[1]} ${TP[0]} ${TP[2]} ${TP[3]}:${TP[4]}:${TP[5]}" +%s`
	
		if [ $LS -ge $LOG_START -a $LS -lt $LOG_END ]; then
			ENDCTR=0
			THIS_INTERVAL=$(( $LS / $INTERVAL * $INTERVAL ))
			[ ${INT_CTR=0} -eq 0 ] && INT_CTR=$THIS_INTERVAL
			DATA[$THIS_INTERVAL]=$(( ${DATA[$THIS_INTERVAL]=0} + 1 ))
		else
			[ $LS -ge $LOG_END ] && ENDCTR=$(( ${ENDCTR=0} + 1 ))
			[ ${ENDCTR=0} -gt 250 ] && break
		fi
	
		CTR=$(( $CTR + 1 ))
		[ $(( $CTR % 100 )) -eq 0 ] && echo -n "[${spinner[$(( $CTR % 99 % 4 ))]}]"
	done
	exec 250>&-

	[ $CTR -eq 0 ] && echo -e "Done.  No lines processed." && return
	
	[ $LOG_END -eq 9999999999 ] && LOG_END=$LS
	
	END_TIME=`date +%s`
	[ $END_TIME -gt $START_TIME ] && echo "[$CTR lines in $(( $END_TIME - $START_TIME )) seconds, $(( ${CTR=1} / ($END_TIME - $START_TIME))) h/s]" || echo "[$CTR lines in less than a second]";

	
	while [ $INT_CTR -lt $LOG_END ]; do
		echo -n `date -d @$INT_CTR "+%m/%d/%Y %H:%M:%S"`
		HPS=`echo 2 k ${DATA[$INT_CTR]=0} $INTERVAL / p | dc`
		echo " : ${DATA[$INT_CTR]=0} ( $HPS hits/sec )"
		INT_CTR=$(( $INT_CTR + $INTERVAL ))
	done

	unset LOG_FILE LOG_START LOG_END INTERVAL START_TIME END_TIME INT_CTR OPTIND DATA
}

# Summarizes top 5 heaviest directories
#
function disk_finder
{
	[ ! -d "$1" ] && DIR=/ || DIR=$1

	find $DIR -depth -mount -maxdepth 2 -mindepth 2 -type d -exec du -s {} \; | sort -k1 -g | awk '{printf("%5.2dG\t%s\n", $1/1024000,  $2) }' | tail -5
	unset DIR
}

# Totals memory usage across multiple processes and gives an average.  Useful for apache planning, etc...
function avg_process_rss
{
	[ ! "$1" ] && echo "Must pass process name" && return

	SUM=0
	CTR=0

	for rss in `ps aux | grep $1 | grep -v grep | awk '{print $6}'`; do 
		SUM=$(( $SUM + $rss ))
		CTR=$(( $CTR + 1 ))
	done

	AVG=$(( $SUM / $CTR ))
	echo "$1 Average Memory usage: ${AVG}k"

	unset SUM CTR
}

# Total Used RSS - duh
function total_used_rss
{
	SUM=0;
	for mem in `ps aux | awk '{print $6}' | grep ^[0-9]`; do SUM=$(( $SUM + $mem )); done
	echo "Total Physical Memory: ${SUM}k"
	
	unset SUM mem
}

# Check changelog for CVE's in a ticket

function backport_check
{
	if [ $# -ne 1 ]; then
		echo "Usage: backport_check <ticket_text_file>"
		echo "Copy customer text with CVE numbers into a file and pass it in"
		return 1
	fi

	for CVE in `grep -Ei 'CVE-[0-9]{4}-[0-9]+' $1 | sort -u`; do 
		echo -en "$CVE: " 
		PATCHED=`rpm -qa --changelog | grep $CVE`
		[ "$PATCHED" ] && echo 'Patched' || echo 'Patch not found' 
		unset PATCHED
	done

	unset PATCHED CVE
}

function verify_key_cert
{
    function usage
    {
        echo "verify_key_cert by Rev. Dr. Aaron M. Segura"
        echo "Usage: verify_key_cert -k <keyfile> -c <certfile>>"

        [ "$1" ] && echo -e "\n*!* $@ \n"
    }

    unset OPTIND
    while getopts ":f:s:e:i:t:" opt; do
        case $opt in
            "f") 
				[ "$KEYFILE" -o "$CERTFILE" ] && usage "-f may not be used with -c or -k" && return
			 	[ -s $opt ] && PAIRFILE=$opt
			;;

			"k")
				[ "$PAIRFILE" ] && usage "-k may not be used with -f"
			;;
		esac
	done
}	

function proc_smaps_top50
{
	 egrep 'p |Size' /proc/$1/smaps | tr '\n' ' ' | sed s/'kB'/'='/g | tr '=' '\n' | awk {'print $6" "$7" "$8'} | sort -rnk3 | head -n 50
}

# Shows swap usage per process
function swap_usage
{
	for PID in `ps -A -o \%p --no-headers | egrep -o '[0-9]+'` ; do
        	if [ -d /proc/$PID ]; then
                	PROGNAME=`cat /proc/$PID/cmdline | tr '\000' '\t'  | cut -f1`
                	for SWAP in `grep Swap /proc/$PID/smaps 2>/dev/null| awk '{ print $2 }'`; do
                        	SUM=$(( $SUM+$SWAP ))
                	done
                	[ $SUM -ne 0 ] && echo "PID=$PID - Swap used: ${SUM}kb - ( $PROGNAME )"
                	OVERALL=$(( $OVERALL+$SUM ))
                	SUM=0
        	fi
	done
	
	if [ $OVERALL -gt $(( 1024 * 1024 )) ]; then
        	HUMAN="$( echo 2 k $OVERALL 1024 /  1024 / p | dc )GB"
	else
        	if [ $OVERALL -gt 1024 ]; then
                	HUMAN="$( echo 2 k $OVERALL 1024 / p | dc )MB"
        	else
                	HUMAN="${OVERALL}KB"
        	fi
	fi
	
	echo "Overall swap used: ${HUMAN}"
	
	unset HUMAN OVERALL SUM PID
}

###
### Nimbus Audits!
###

function nimbus_config_to_vars
{
	while read PAIR; do
		VARNAME=`echo $PAIR | awk '{print $1}'`

		VALUE=`echo $PAIR | cut -d= -f2- | egrep -o '[^ ].*'`
		if [ "$VALUE" ]; then
			EXPORTS="export $1${VARNAME}=\"$VALUE\"; $EXPORTS"
		fi
	done

	echo $EXPORTS
	unset EXPORTS
}

function nimbus_config_unset_vars
{
	for val in `echo $1 | egrep -o '([a-z_]+)=' | cut -d= -f1`; do unset $val; done
}

function nimbus_disk_audit
{
	TMPFILE=/tmp/.$$.nimbus_disk_audit

	echo "------------------------------------------------------"
	echo "~  Disk Monitoring                                   ~"
	echo "------------------------------------------------------"
	
	if [ -s /opt/nimsoft/probes/system/cdm/cdm.cfg ]; then
		CDMCFG=/opt/nimsoft/probes/system/cdm/cdm.cfg
	else
		if [ -s /opt/nimbus/probes/system/cdm/cdm.cfg ]; then
			CDMCFG=/opt/nimbus/probes/system/cdm/cdm.cfg
		else
			echo "Could not find cdm.cfg.  Giving up..."
			return 1
		fi
	fi
	
	ACTIVE=`sed -rn "/^<disk>/,/<\/disk>/ { /<alarm>/,/active/ { /active =/ p }}" $CDMCFG | awk '{print $3}'`
	INTERVAL=`sed -rn "/^<disk>/,/interval =/ { /interval/ p }" $CDMCFG | cut -d= -f2- | egrep -o '[^ ].*'`
	SAMPLES=`sed -rn "/^<disk>/,/samples =/ { /samples/ p}" $CDMCFG | cut -d= -f2 | egrep -o '[^ ].*'`
	IGNOREFS=`sed -rn "/^<disk>/,/ignore_filesystem/ { /ignore_filesystem/ p}" $CDMCFG | awk '{print $3}'`
	IGNOREDEV=`sed -rn "/^<disk>/,/ignore_device/ { /ignore_device/ p}" $CDMCFG | awk '{print $3}'`

	if [ "$( echo $ACTIVE | grep -i yes )" ]; then
		echo "$(pad "Alarms Active:" 25)$ACTIVE"
		echo "$(pad "Polling Interval:" 25)$INTERVAL"
		echo "$(pad "Number of Samples:" 25)$SAMPLES"
		
		[ "$IGNOREDEV" ] && echo -en "\n$(pad "Ignoring Devices:" 25)$IGNOREDEV" 
		[ "$IGNOREFS" ] && echo -en "\n$(pad "Ignoring Filesystems:" 25)$IGNOREFS"
	
		unset ACTIVE INTERVAL SAMPLES IGNOREDEV IGNOREFS

		echo
	
		for fs in `mount | egrep '(ext[34]|xfs|nfs)' | cut -d\  -f3`; do 
			ID=`echo $fs | tr '/' '#'`; 
			sed -rn "/<$ID>/,/<\/#/ p" /opt/nim*/probes/system/cdm/cdm.cfg > $TMPFILE
			
			if [ ! -s $TMPFILE ]; then
				echo -e "[$fs] INACTIVE, Not Configured\n"
			else	
				ACTIVE=`sed -rn "/<$ID>/,/active =/ { /active/ p }" $CDMCFG | awk '{ print $3 }' | grep -i yes`
				echo -n "[$fs] "
	
				if [ "$ACTIVE" ]; then
					echo "Active"
		
					QOSSPACE=`egrep '^[[:space:]]*qos_disk_usage' $TMPFILE | awk '{print $3}'`
					QOSINODE=`egrep '^[[:space:]]*qos_inode_usage' $TMPFILE | awk '{print $3}'`
		
					echo -n "- $(pad "Sending QOS" 15)[Space:"
					[ "$( echo $QOSSPACE | grep -i yes)" ] && echo -n "Yes" || echo -n "*NO*"
					echo -n "] [Inodes:" 
					[ "$( echo $QOSINODE | grep -i yes)" ] && echo -n "Yes" || echo -n "*NO*"
					echo "]"
					unset QOSSPACE QOSINODE	
	
					# Space Usage
					PCT=`egrep '^[[:space:]]+percent =' $TMPFILE | awk '{print $3}'`
					[ "$PCT" == "no" ] && UNIT="MB" || UNIT="%"
			
					WARNING_ACTIVE=`sed -rn '/<warning>/,/<\/warning>/ { /active/ p }' $TMPFILE | awk '{ print $3 }'`
					WARNING_THRESH=`sed -rn '/<warning>/,/<\/warning>/ { /threshold/ p }' $TMPFILE | awk '{ print $3 }'`
					
					ERROR_ACTIVE=`sed -rn "/<error>/,/<\/error>/ { /active/ p }" $TMPFILE | awk '{ print $3 }'`
					ERROR_THRESH=`sed -rn "/<error>/,/<\/error>/ { /threshold/ p }" $TMPFILE | awk '{ print $3 }'`
			
					echo -n "- $(pad "Space Warning" 15)"
					[ "$( echo $WARNING_ACTIVE | grep -i yes )" ] && \
						echo "$WARNING_THRESH$UNIT" || \
							echo "INACTIVE"
	
					echo -n "- $(pad "Space Error" 15)"
					[ "$( echo $ERROR_ACTIVE | grep -i yes )" ] && \
						echo "$ERROR_THRESH$UNIT" || \
						echo "INACTIVE"
			
					unset PCT UNIT WARNING_ACTIVE WARNING_THRESH ERROR_ACTIVE ERROR_THRESH
			
					# Inode Usage
					PCT=`egrep '^[[:space:]]+inode_percent =' $TMPFILE | awk '{print $3}'`		
					[ "$PCT" == "no" ] && UNIT="MB" || UNIT="%"
			
					WARNING_ACTIVE=`sed -rn '/<inode_warning>/,/<\/inode_warning>/ { /active/ p }' $TMPFILE | awk '{ print $3 }'`
					WARNING_THRESH=`sed -rn '/<inode_warning>/,/<\/inode_warning>/ { /threshold/ p }' $TMPFILE | awk '{ print $3 }'`
					
					ERROR_ACTIVE=`sed -rn "/<inode_error>/,/<\/inode_error>/ { /active/ p }" $TMPFILE | awk '{ print $3 }'`
					ERROR_THRESH=`sed -rn "/<inode_error>/,/<\/inode_error>/ { /threshold/ p }" $TMPFILE | awk '{ print $3 }'`
			
					echo -n "- $(pad "Inode Warning" 15)"
					[ "$( echo $WARNING_ACTIVE | grep -i yes )" ] && \
						echo "$WARNING_THRESH$UNIT" || \
						echo "INACTIVE"
	
					echo -n "- $(pad "Inode Error" 15)"
					[ "$( echo $ERROR_ACTIVE | grep -i yes )" ] && \
						echo "$ERROR_THRESH$UNIT" || \
						echo "INACTIVE"
			
					unset PCT UNIT WARNING_ACTIVE WARNING_THRESH ERROR_ACTIVE ERROR_THRESH
	
					# Delta Usage
					PCT=`egrep '^[[:space:]]+delta_percent =' $TMPFILE | awk '{print $3}'`		
					[ "$PCT" == "no" ] && UNIT="MB" || UNIT="%"
			
					WARNING_ACTIVE=`sed -rn '/<delta_warning>/,/<\/delta_warning>/ { /active/ p }' $TMPFILE | awk '{ print $3 }'`
					WARNING_THRESH=`sed -rn '/<delta_warning>/,/<\/delta_warning>/ { /threshold/ p }' $TMPFILE | awk '{ print $3 }'`
					
					ERROR_ACTIVE=`sed -rn "/<delta_error>/,/<\/delta_error>/ { /active/ p }" $TMPFILE | awk '{ print $3 }'`
					ERROR_THRESH=`sed -rn "/<delta_error>/,/<\/delta_error>/ { /threshold/ p }" $TMPFILE | awk '{ print $3 }'`
			
					echo -n "- $(pad "Delta Warning" 15)"
					[ "$( echo $WARNING_ACTIVE | grep -i yes )" ] && \
						echo "$WARNING_THRESH$UNIT" || \
						echo "INACTIVE"
	
					echo -n "- $(pad "Delta Error" 15)"
					[ "$( echo $ERROR_ACTIVE | grep -i yes )" ] && \
						echo "$ERROR_THRESH$UNIT" || \
						echo "INACTIVE"
		
					unset PCT UNIT WARNING_ACTIVE WARNING_THRESH ERROR_ACTIVE ERROR_THRESH
				else
					echo "*INACTIVE*"
				fi
			fi
			echo	
		done
	fi

	rm -f $TMPFILE
	unset CDMCFG TMPFILE
}

function nimbus_cpu_audit
{
	TMPFILE=/tmp/.$$.nimbus_sys_audit
	
	echo "------------------------------------------------------"
	echo "~  CPU Monitoring                                    ~"
	echo "------------------------------------------------------"

	if [ -s /opt/nimsoft/probes/system/cdm/cdm.cfg ]; then
		CDMCFG=/opt/nimsoft/probes/system/cdm/cdm.cfg
	else
		if [ -s /opt/nimbus/probes/system/cdm/cdm.cfg ]; then
			CDMCFG=/opt/nimbus/probes/system/cdm/cdm.cfg
		else
			echo "Could not find cdm.cfg.  Giving up..."
			return 1
		fi
	fi

	sed -rn "/<cpu>/I,/<\/cpu>/ p" /opt/nim*/probes/system/cdm/cdm.cfg > $TMPFILE
	
	if [ ! -s $TMPFILE ]; then
		echo -e "Something broke horribly.  Could not find \<cpu\> clause.";
	else
		ACTIVE=`sed -rn "/<alarm>/,/active/ { /active/ p }" $TMPFILE | awk '{print $3}'`

		if [ "$( echo $ACTIVE | grep -i yes )" ]; then	
			INTERVAL=`egrep '^[[:space:]]*interval' $TMPFILE | cut -d= -f2- | egrep -o '[^ ].*'`
			SAMPLES=`egrep '^[[:space:]]*samples' $TMPFILE | cut -d= -f2 | egrep -o '[^ ].*'`
	
			echo "Alarms Active:     $ACTIVE"
			echo "Polling Interval:  $INTERVAL"
			echo "Number of Samples: $SAMPLES"
			unset INTERVAL SAMPLES ACTIVE
		
			QOSVALS=`grep qos_cpu $TMPFILE | nimbus_config_to_vars`
			eval "$QOSVALS"	

			for type in multi_idle multi_wait multi_system multi_user multi_usage idle wait system user usage; do
				VAR="qos_cpu_$type"
				[ "$( echo ${!VAR} | grep -i yes )" ] && OUTPUT="- $(pad "$type:" 15)Yes\n$OUTPUT" || OUTPUT="- $(pad "$type:" 15)*NO*\n$OUTPUT"
			done

			echo -e "\nSending QOS:\n$OUTPUT"	

			nimbus_config_unset_vars "$QOSVALS"
			unset OUTPUT VAR QOSVALS 

			echo "Monitoring Thresholds:"

			QLENACTIVE=`sed -rn "/<proc_q_len>/,/active/ { /active/ p }" $TMPFILE | awk '{print $3}'`
			QLENTHRESH=`sed -rn "/<proc_q_len/,/threshold/ { /threshold/ p}" $TMPFILE | awk '{print $3}'`
			NUMCORES=`grep processor /proc/cpuinfo | wc -l`

			echo -n "- $(pad "Queue Length Monitor" 25)"
			[ "$( echo $QLENACTIVE | grep -i yes )" ] && \
				echo "$QLENTHRESH ($NUMCORES available cores)" || \
				echo "INACTIVE"
	
			unset QLENACTIVE QLENTHRESH NUMCORES

			CPUWARNINGACTIVE=`sed -rn "/<warning>/,/<\/warning>/ { /active/ p }" $TMPFILE | awk '{print $3}'`
			CPUERRORACTIVE=`sed -rn "/<error>/,/<\/error>/       { /active/ p }" $TMPFILE | awk '{print $3}'`
	
			CPUWARNINGTHRESH=`sed -rn "/<warning>/,/<\/warning>/ { /threshold =/ p }" $TMPFILE | awk '{print $3}'`
			CPUERRORTHRESH=`sed -rn "/<error>/,/<\/error>/       { /threshold =/ p }" $TMPFILE | awk '{print $3}'`
	
			echo -n "- $(pad "Total CPU Usage Warning" 25)"
			[ "$(echo $CPUWARNINGACTIVE | grep -i yes)" ] && \
				echo "$CPUWARNINGTHRESH" || \
				echo "INACTIVE"

			echo -n "- $(pad "Total CPU Usage Error" 25)"
			[ "$(echo $CPUERRORACTIVE | grep -i yes )" ] && \
				echo "$CPUERRORTHRESH" || \
				echo "INACTIVE"

			unset CPUWARNINGACTIVE CPUERRORACTIVE CPUWARNINGTHRESH CPUERRORTHRESH

			MCPUERRORACTIVE=`sed -rn "/<multi_max_error>/,/<\/multi_max_error>/  { /active/ p }" $TMPFILE | awk '{print $3}'`
			MCPUDIFFACTIVE=`sed -rn "/<multi_diff_error>/,/<\/multi_diff_error>/ { /active/ p }" $TMPFILE | awk '{print $3}'`

			MCPUERRORTHRESH=`sed -rn "/<multi_max_error>/,/<\/multi_max_error>/  { /threshold =/ p }" $TMPFILE | awk '{print $3}'`
			MCPUDIFFTHRESH=`sed -rn "/<multi_diff_error>/,/<\/multi_diff_error>/ { /threshold =/ p }" $TMPFILE | awk '{print $3}'`

			echo -n "- $(pad "Single CPU Usage Error" 25)"
			[ "$(echo $MCPUERRORACTIVE | grep -i yes )" ] && \
				echo "$MCPUERRORTHRESH" || \
				echo "INACTIVE"

			echo -n "- $(pad "Single CPU Diff Max" 25)"
			[ "$(echo $MCPUDIFFACTIVE | grep -i yes )" ] && \
				echo "$MCPUDIFFTHRESH"	|| \
				echo "INACTIVE"

			unset MPCUERRORACTIVE MCPUDIFFACTIVE MCPUERRORTHRESH MCPUDIFFTHRESH
		else
			echo "**** INACTIVE ****"
		fi
	fi

	echo
	rm -f $TMPFILE
	unset CDMCFG TMPFILE
}

function nimbus_processes_audit
{
	TMPFILE=/tmp/.$$.nimbus_proc_audit

	CHECKFOR="memcached rabbitmq-server mysqld httpd ntpd"	

	echo "------------------------------------------------------"
	echo "~  Process Monitoring                                ~"
	echo "------------------------------------------------------"

	if [ -s /opt/nimsoft/probes/system/processes/processes.cfg ]; then
		PROCCFG=/opt/nimsoft/probes/system/processes/processes.cfg
	else
		if [ -s /opt/nimbus/probes/system/processes/processes.cfg ]; then
			PROCCFG=/opt/nimbus/probes/system/processes/processes.cfg
		else
			echo "Could not find processes.cfg.  Giving up..."
			return 1
		fi
	fi

	sed -rn "/<watchers>/,/<\/watchers>/ p" $PROCCFG > $TMPFILE
	
	if [ ! -s $TMPFILE ]; then
		echo -e "Something broke horribly.  Could not find \<watchers\> clause.";
	else
		INTERVAL=`sed -rn '/<setup>/,/<\/setup>/ { /interval/p }' $PROCCFG | cut -d= -f2- | egrep -o '[^ ].*'`
		SAMPLES=`sed -rn '/<setup>/,/<\/setup>/ { /samples/p }' $PROCCFG | cut -d= -f2- | egrep -o '[^ ].*'`

		echo "Interval:    $INTERVAL"
		echo "Samples:     $SAMPLES"
		echo  ""
		unset INTERVAL SAMPLES

		CONFIGURED=`egrep '<[^/]' $TMPFILE | egrep -v 'window|watchers' | egrep -o '[a-zA-Z_-\.]+'`

		for proc in $CONFIGURED; do
			SCANVARS=`sed -rn "/<$proc>/,/<\/$proc>/p" $TMPFILE | sed -rn '/<window>/,/<\/window>/!p' | egrep -v "<[/]*$proc>" | nimbus_config_to_vars`
			eval "$SCANVARS"	
			echo "$proc	($description)"

			if [ "$( echo $active | grep -i 'yes' )" ]; then
				echo    "- Active:            $active"
				echo -n "- Scanning For:      "
				[ "$( echo $scan_proc_cmd_line | grep -i 'yes')" ] && echo "$proc_cmd_line" || echo "$process"
				[ "$( echo $scan_proc_owner | grep -i 'yes')" ] && echo "- Process Owner:     $user"
				[ "$( echo $scan_size  | grep -i 'yes')" ] && echo "- Process Size:      Min:${min_size=undef} Max:${max_size=undef}"
				[ "$( echo $scan_proc_parent| grep -i 'yes')" ] && echo "- Process Parent:    $scan_proc_parent_name"
				[ "$( echo $scan_threads | grep -i 'yes')" ] && echo "- Process Threads:   Min:${thread_count_min=undef} Max:${thread_count_max=undef}"
				echo    "- Report when:       $report"
				echo -n "- Action on Failure: $action"
				[ "$( echo $action | grep -v none )" ] && echo ", cmd:[$command $arguments]" || echo
			else
				echo "- Active: *NO*"
			fi		

			echo
			nimbus_config_unset_vars "$SCANVARS"
			unset SCANVARS
		done
		unset CONFIGURED proc
	fi

	for check in $CHECKFOR; do
		RUNNING=`pidof -xs $check`
	
		if [ "$RUNNING" ]; then
			if [ ! "$( egrep process\\s\*=\\s\**$check $TMPFILE)" ]; then
				NOTIFY="\t$check[$RUNNING]\n$NOTIFY"
			fi
		fi
	done

	[ "$NOTIFY" ] && echo -e "Processes running, but not currently being monitored:\n   $NOTIFY"

	rm -f $TMPFILE
	unset NOTIFY RUNNING CHECKFOR TMPFILE PROCCFG
}

function nimbus_memory_audit
{
	TMPFILE=/tmp/.$$.nimbus_memory_audit
	
    echo "------------------------------------------------------"
    echo "~  Memory Monitoring                                 ~"
    echo "------------------------------------------------------"

    if [ -s /opt/nimsoft/probes/system/cdm/cdm.cfg ]; then
        CDMCFG=/opt/nimsoft/probes/system/cdm/cdm.cfg
    else
        if [ -s /opt/nimbus/probes/system/cdm/cdm.cfg ]; then
            CDMCFG=/opt/nimbus/probes/system/cdm/cdm.cfg
        else
            echo "Could not find cdm.cfg."
            return 1
        fi
    fi

	sed -rn '/<memory>/,/<\/memory>/p' $CDMCFG > $TMPFILE

	if [ ! -s $TMPFILE ]; then
		echo "Something went horribly wrong.  Could not parse <memory> section of $CDMCFG"
	else
		ACTIVE=`sed -rn '/<alarm>/,/active/ { /active/p }' $TMPFILE        | awk '{print $3}'`

		if [ "$( echo $ACTIVE | grep -i yes )" ]; then
			INTERVAL=`sed -rn '/<memory>/,/interval/ { /interval/p }' $TMPFILE | awk '{print $3}'`
			SAMPLES=`sed -rn '/<memory>/,/samples/ { /samples/p }' $TMPFILE    | awk '{print $3}'`

			echo "Active:      Yes"
			echo "Interval:    $INTERVAL"
			echo "Samples:     $SAMPLES"

			unset INTERVAL SAMPLES

			QOSVARS=`grep qos_memory $TMPFILE | nimbus_config_to_vars`
			eval "$QOSVARS"

			for val in usage physical swap paging; do 
				VAR="qos_memory_$val"
				[ "$( echo ${!VAR} | grep -i yes )" ] && OUTPUT="[$val:Yes] $OUTPUT" || OUTPUT="[$val:*NO*] $OUTPUT"
			done
			echo "Sending QOS: $OUTPUT"	

			nimbus_config_unset_vars "$QOSVARS"	
			unset OUTPUT QOSVARS VAR
		
			echo
	
			for alert in physical pagefile paging swap; do
				for sev in warning error; do
					ALERTVARS=`sed -rn "/<$alert $sev>/,/<\/$alert $sev>/p" $TMPFILE | egrep -v '<|>' | nimbus_config_to_vars`
					eval $ALERTVARS

					if [ "$( echo $active | grep -i yes )" ]; then
						echo "- $(pad "$alert $sev:" 20)$threshold"
					else
						echo "- $(pad "$alert $sev:" 20)INACTIVE"
					fi
					nimbus_config_unset_vars "$ALERTVARS"
					unset ALERTVARS
				done
			done
		else
			echo "Active:  *** NO ***"
		fi
	fi
	
	rm -f TMPFILE
	unset TMPFILE CDMCFG ACTIVE
}

function pad
{
	LEN=${#1}
	PAD=$(( $2 - $LEN ))

	echo -n $1

	while [ $PAD -gt 0 ]; do
		OUT="$OUT "
		PAD=$(( $PAD - 1 ))
	done
	
	echo -n "$OUT"
	unset OUT PAD LEN
}

function nimbus_cdm_audit
{
	nimbus_cpu_audit;
	nimbus_disk_audit;
	nimbus_memory_audit;
}

function nimbus_full_audit
{
	echo "------------------------------------------------------"
	echo "~  Nimbus Robot Audit                                ~"
	echo "------------------------------------------------------"

	if [ -s /opt/nimsoft/robot/controller.cfg ]; then
		NIMCFG=/opt/nimsoft/robot/controller.cfg
	else
		if [ -s /opt/nimbus/robot/controller.cfg ]; then
			NIMCFG=/opt/nimbus/robot/controller.cfg
		else
			echo "Could not find controller.cfg.  This is very wrong.  All your Nimbus are probably fux0red."
			return 1
		fi
	fi

	CHILDREN=`egrep '^<[a-z]+>' $NIMCFG | tr -d '<>'`

	for child in $CHILDREN; do
		CONFIG=`sed -rn "/<$child>/,/<\/$child>/p" $NIMCFG | egrep -v "<[/]*$child>" | nimbus_config_to_vars`

		eval "$CONFIG"
		echo "$child process:"
		if [ "$( echo $active | grep -i 'yes' )" ];then
			PIDOF=`pidof nimbus\($child\)`
			echo "- Active:   $active" 
			echo "- Desc:     $description"
			echo "- Group:    $group"
			echo "- Type:     $type"
			
		 	[ "$PIDOF" ] && echo "- PID:      $( pidof nimbus\(${child}\) )" || echo "- ***NOT CURRENTLY RUNNING***"
				
			[ "$group" == "System" ] && [ "$active" == "yes" ] && AUDIT="$child $AUDIT"
		else
			echo "- Active:   ***NO***"
		fi
	
		echo
		nimbus_config_unset_vars "$CONFIG"
		unset CONFIG PIDOF
	done	
	
	for section in $AUDIT; do
		nimbus_${section}_audit
	done

	unset CHILDREN AUDIT NIMCFG
}

function raid_layout
{
  OMLOCATIONS="/opt/dell/srvadmin/bin/omreport /usr/bin/omreport"
  OM=

  for location in $OMLOCATIONS; do
          [ -x $location ] && OM=$location
  done
  
  if [ ! "$OM" ]; then
          echo "Couldn't find OMREPORT $OM"
          return
  fi
  
  TMPFILE=/tmp/.raid_layout.$$
  
  CONTROLLERS=`$OM storage controller | awk '/^ID/ { print $3 }'`
  
  for ctrl in $CONTROLLERS; do
          echo "* Controller $ctrl"
          # dump all pdisks on controller to TMPFILE
          $OM storage pdisk controller=$ctrl > ${TMPFILE}.pdisks
  
          # dump info for all vdisks on controller
          $OM storage vdisk controller=$ctrl > ${TMPFILE}.vdisks
  
          VDISKS=`awk '/^ID/ { print $3 }' ${TMPFILE}.vdisks`
          for vdisk in $VDISKS; do
                  VDISKS=`awk '/^ID/ { print $3 }' ${TMPFILE}.vdisks`
                  SEDFILTER="/ID\s*:\s+$vdisk/,/^\s*$/"
                  RAIDSIZE=`sed -rn "$SEDFILTER { /^Size/p}" ${TMPFILE}.vdisks | awk '{ print $3 " " $4}'`
                  RAIDSTATE=`sed -rn "$SEDFILTER { /^Status/p}" ${TMPFILE}.vdisks | awk '{ print $3}'`
                  RAIDTYPE=`sed -rn "$SEDFILTER { /^Layout/p}" ${TMPFILE}.vdisks | awk '{ print $3}'`
  
                  echo "|-Virtual Disk $vdisk [$RAIDSTATE] ($RAIDTYPE @ $RAIDSIZE)"
  
                  # Get IDs for pdisks involved
                  PDISKS=`$OM storage pdisk vdisk=$vdisk controller=$ctrl | awk '/^ID/ { print $3}'`
                  for pdisk in $PDISKS; do
                          SEDFILTER="/^ID\s*:\s*$pdisk/,/^\s*$/"
                          DISKSTATE=`sed -rn "$SEDFILTER { /^Status/p}" ${TMPFILE}.pdisks | awk '{print $3}'`
                          DISKSIZE=`sed -rn "$SEDFILTER { /^Used/p}"   ${TMPFILE}.pdisks | awk '{print $6 " " $7}'`
  
                          echo "| |-- Disk $pdisk [$DISKSTATE] $DISKSIZE"
                  done
          done
          rm -f ${TMPFILE}.pdisks
          rm -f ${TMPFILE}.vdisks
  done
}


function network_states
{
  netstat -ant | awk '{print $6}'  | egrep '^[A-Z_]+$' | sort | uniq -c | sort -rn
}

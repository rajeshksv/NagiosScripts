#!/bin/bash
#===============================================================================
#
#          FILE:  check_disk_io.sh
#
#         USAGE:  ./check_disk_io.sh
#
#   DESCRIPTION:  Check the disk I/O's in kb/s across all physical disks.
#
#       OPTIONS:  -w WARN_READ -c CRITICAL_READ
#                 -e WARN_WRITE -v CRITICAL_WRITE [-p] [-h]
#  REQUIREMENTS:  /proc/diskstats exists, [e]grep, awk installed
#          BUGS:  ---
#         NOTES:  systat only gives in average, hence this script
#        AUTHOR:  Sebastian Grewe (), sebastiang@jammicron.com
#       COMPANY:  Jammicron Technology Corp.
#       VERSION:  0.1
#       CREATED:  04/12/08 02:08:03 PM PST
#      REVISION:  14
#===============================================================================

function get_partitions() {
	local DISKS=`cat /proc/partitions | egrep -v "(md.*$|major|^$|[[:digit:]]$)" | awk '{print $4}'`
	echo $DISKS
}

function parse_arguments() {
	while getopts 'w:c:e:v:hp' OPT; do
	 case $OPT in
	   w)  RWARN=$OPTARG;;
	   c)  RCRIT=$OPTARG;;
	   e)  WWARN=$OPTARG;;
	   v)  WCRIT=$OPTARG;;
	   h)  HELP=1;;
	   p)  PERF=1;;
	   *)  HELP=1;;
	 esac
	done
	# usage
	HELP="
	    usage: $0 [ -w value -c value -p -h ]
	
	    syntax:
	
            -w --> Warning integer value outgoing traffic
            -c --> Critical integer value outgoing traffic
            -e --> Warning integer value incoming traffic
            -v --> Critical integer value incoming traffic
            -p --> print out performance data
            -h --> print this help screen
"
	if [ "$HELP" = "yes" -o $# -lt 8 ]; then
	  echo "$HELP"
	  exit 0
	fi
}

function status() {
        
	if [[ $READS -lt $RWARN ]]; then
                MSG="read kb/s normal"
                [[ $EXIT != 2 && $EXIT != 1 ]] && EXIT=0 && STATUS="OK"
        elif [[ $READS -lt $RCRIT ]]; then
                MSG="read kb/s anormal"
                [[ $EXIT != 2 ]] && EXIT=1 && STATUS="WARNING"
        elif [[ $READS -ge $RCRIT ]]; then
                MSG="read kb/s critical"
                STATUS="CRITICAL"
                EXIT=2
        fi
        
	if [[ $WRITES -lt $WWARN ]]; then
                MSG="$MSG, write kb/s normal"
                [[ $EXIT != 2 && $EXIT != 1 ]] && EXIT=0 && STATUS="OK"
        elif [[ $WRITES -lt $WCRIT ]]; then
                MSG="$MSG, write kb/s anormal"
                [[ $EXIT != 2 ]] && EXIT=1 && STATUS="WARNING"
        elif [[ $WRITES -ge $WCRIT ]]; then
                MSG="$MSG, write kb/s critical"
                STATUS="CRITICAL"
                EXIT=2
        fi

	[[ $PERF == 1 ]] && PERF="| writes=$WRITES;$WWARN;$WCRIT;; reads=$READS;$RWARN;$RCRIT;;"
}

function output() {
	echo "$STATUS - $MSG $PERF"
}

function get_mb() {
	local DISKS=$1
	for disk in $DISKS; do
		grep "\<$disk\>" /proc/diskstats | awk '{print ($6*512)/1024" "($10*512)/1024}'
	done | awk 'BEGIN {rt=0;wt=0} {rt+=$1;wt+=$2} END {print int(rt)"|"int(wt)}'
}

function get_kbs() {
        local DISKS=$1

        MB=`get_mb "$DISKS"` 
        WRITE1=${MB##*|}
        READ1=${MB%%|*}

        sleep 5

        MB=`get_mb "$DISKS"`
        WRITE2=${MB##*|}
        READ2=${MB%%|*}
        
        ((WRITES=($WRITE2-$WRITE1)/5))
        ((READS=($READ2-$READ1)/5))
}


function main() {
	parse_arguments $@
	get_kbs "`get_partitions`"
	status
	output
}

main $@

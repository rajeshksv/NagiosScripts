#!/bin/bash

# Nagios plugin exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

while getopts "c:w:" OPT; do
	case $OPT in
		w) WARNING_PC=$OPTARG ;;
		c) CRITICAL_PC=$OPTARG ;;
	esac
done

if [ -z "$WARNING_PC" -o -z "$CRITICAL_PC" ]; then
	echo "Usage: $0 -w <warning percentage> -c <critical percentage>"
	exit $STATE_UNKNOWN
fi

# The values from /proc/meminfo are in KiB (even though the output prints kB),
# convert them to B to prevent ambiguity later on, and insert them as variables.
eval "$(sed -r '
		y/()/_ /
		s/ *: *([0-9]*).*/=$((\1 * 1024))/
		s/([a-z])([A-Z])/\1_\2/g
		s/.*/\U\0/
		' /proc/meminfo)"


# Some systems don't have these values, default them
SRECLAIMABLE=${SRECLAIMABLE:-0}


# The idiomatic 'used memory' computation
USED=$((MEM_TOTAL - MEM_FREE - BUFFERS - CACHED - SRECLAIMABLE))
USED_PC=$((100 * USED / MEM_TOTAL))


# And some more components for reporting purposes
USED_TOTAL=$((MEM_TOTAL - MEM_FREE))
SWAP_USED=$((SWAP_TOTAL - SWAP_FREE))
REST=$((USED - SRECLAIMABLE))


if [ $USED_PC -ge $CRITICAL_PC ]; then
	STATE="CRITICAL";
elif [ $USED_PC -ge $WARNING_PC ]; then
	STATE="WARNING";
else
	STATE="OK";
fi

echo "$STATE - $USED_PC% used"

eval exit \$STATE_$STATE

#!/bin/bash

get_labels() {
	for l in $* ; do
		cat "${l}" | sed 's/\s/_/g'
	done
}

get_temps() {
	for l in $* ; do
		echo $(( $(cat "${l%label}input") / 1000 ))
	done
}

TEMP_LABELS="$(ls -1 /sys/bus/platform/devices/coretemp.0/hwmon/hwmon3/temp*_label)"

get_labels ${TEMP_LABELS} | tr '\n' ' '
echo
get_temps ${TEMP_LABELS} | tr '\n' ' '
echo

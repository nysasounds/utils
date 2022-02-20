#!/bin/bash

ls -1 /sys/bus/platform/devices/coretemp.0/hwmon/hwmon1/temp*_label | while read l ; do

	LABEL="$(cat "${l}")"
	TEMP="$(cat "${l%label}input")"

	echo ${LABEL// /.}: $(( $TEMP / 1000 ))

done

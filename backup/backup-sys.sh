#!/bin/bash

set -u

# Location of backup store and config #
BAK_STORE="${1:-/this/path/does/not/exit}"
BAK_EXCLD="${BAK_STORE}/sys.xcld"
BAK_LIST="${BAK_STORE}/sys.list"

# Optional label for backup set #
BAK_LABEL="${2:-"WEEKLY"}"

# Defatul times for retension of weekly or monthly backups #
MONTHLY_ARCHIVE_AGE="365"
WEEKLY_ARCHIVE_AGE="31"

DATE_STAMP=$(/bin/date +"%Y-%m-%d_%H-%M")
export START_TIME=$(/bin/date -u +"%s")

BAK_PREFIX="${BAK_PREFIX:-$(/bin/hostname)}"

LOG="${BAK_STORE}/${BAK_PREFIX}_${BAK_LABEL}_${DATE_STAMP}.log"

MOUNT_BOOT="no"

EXIT_STATUS=0


header() {

cat << END

Backup up prefix: ${BAK_PREFIX}

Configs:
$(cat ${BAK_LIST})

Log:          $LOG

Start Time:   $DATE_STAMP

Excluding:
$(cat "${BAK_EXCLD}")

Currently mounted:
$(/bin/mount)

END

}


backup() {

BAK_FILE="${BAK_STORE}/${BAK_PREFIX}-${BAK_NAME}_${BAK_LABEL}_${DATE_STAMP}.tar.gz"

echo "Starting ${BAK_NAME} ${BAK_SOURCE}"
/bin/tar zcvf "${BAK_FILE}" -X "${BAK_EXCLD}" "${BAK_SOURCE}" --one-file-system 2>&1

}


backups() {

echo "Changing to /"
pushd /
if [ $? -ne 0 ] ; then
	echo "Couldn't switch to / , exiting..."
	EXIT_STATUS=1
	return $EXIT_STATUS
fi

/bin/mount |grep -Eq "\ on\ \/boot\ " && MOUNT_BOOT="yes"
if [ "${MOUNT_BOOT}" != "yes" ] ; then
	echo "Mounting /boot"
	/bin/mount /boot
fi

# Do backups #
BAK_STATUS=0
cat "${BAK_LIST}" | while read l ; do
	BAK_NAME=${l%% *}
	BAK_SOURCE=${l#* }
	backup || BAK_STATUS=1
done

export BAK_TIME=$((`/bin/date -u "+%s"` - $START_TIME ))
BAK_DATE=$(/bin/date -u -d "@${BAK_TIME}" +"%R:%S")
echo "Total Backup Time: ${BAK_DATE}"
echo

if [ "${MOUNT_BOOT}" != "yes" ] ; then
	echo "Unmounting /boot"
	/bin/umount /boot
fi

if [ "${BAK_STATUS}" != 0 ] ; then
	echo "Backup seemed to fail :("
	echo "Exit status was: ${BAK_STATUS}"
	false
else
	echo "Backup completed OK"
	echo
	echo "Changing from root" ; popd
	rotate
fi

EXIT_STATUS=$?
echo
times
echo

return $EXIT_STATUS

}


rotate() {

cat << END
Removing stale archives:
Standard arachives over		$WEEKLY_ARCHIVE_AGE days old
Monthly arachives over		$MONTHLY_ARCHIVE_AGE days old

END

/usr/bin/find ${BAK_STORE} -type f -mtime +${WEEKLY_ARCHIVE_AGE} -name "${BAK_PREFIX}-*_WEEKLY_*.tar.gz" -exec rm -v {} \;
/usr/bin/find ${BAK_STORE} -type f -mtime +${WEEKLY_ARCHIVE_AGE} -name "${BAK_PREFIX}_WEEKLY_*.log" -exec rm -v {} \;
/usr/bin/find ${BAK_STORE} -type f -mtime +${MONTHLY_ARCHIVE_AGE} -name "${BAK_PREFIX}-*_MONTHLY_*.tar.gz" -exec rm -v {} \;
/usr/bin/find ${BAK_STORE} -type f -mtime +${MONTHLY_ARCHIVE_AGE} -name "${BAK_PREFIX}_MONTHLY_*.log" -exec rm -v {} \;

}


exit_err() {

echo "ERROR: ${1} - exiting..."
exit 1

}


[ -d "${BAK_STORE}" ] || exit_err "Backup destination does not exist"
[ -f "${BAK_LIST}" ] || exit_err "Backup list does not exist"


header >> "${LOG}"
backups >> "${LOG}"

if [ $EXIT_STATUS -ne 0 ] ; then
	echo "Backup Failue"
	cat "${LOG}"
fi

exit $EXIT_STATUS

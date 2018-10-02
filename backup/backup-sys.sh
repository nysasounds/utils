#!/bin/bash

BAKLABEL=${1}
BAKLABEL="${BAKLABEL:-"full-sys"}"

MARCHAGE="365"
WARCHAGE="31"

HOSTN=`/bin/hostname`

DATESTAMP=`/bin/date +"%Y-%m-%d_%H-%M"`
export STARTTIME=`/bin/date -u +"%s"`

BAKSTORE="/home/data/backup/sys/"
EXCLD="${BAKSTORE}/sys.xcld"
BACKPRE="${HOSTN}"
BAKBOOT="${BAKSTORE}/${BACKPRE}-boot_${BAKLABEL}_${DATESTAMP}.tgz"
BAKROOT="${BAKSTORE}/${BACKPRE}-root_${BAKLABEL}_${DATESTAMP}.tgz"
BAKHOME="${BAKSTORE}/${BACKPRE}-home_${BAKLABEL}_${DATESTAMP}.tgz"
BAKVAR="${BAKSTORE}/${BACKPRE}-var_${BAKLABEL}_${DATESTAMP}.tgz"
LOG="${BAKSTORE}/${BACKPRE}_${BAKLABEL}_${DATESTAMP}.log"

EXITSTAT=0


header() {

cat << END

Backup up system: ${HOSTN}

Archive:      $BAKBOOT
Archive:      $BAKROOT
Archive:      $BAKHOME
Archive:      $BAKVAR
Log:          $LOG

Start Time:   $DATESTAMP

Excluding:
`cat $EXCLD`

Currently mounted:
`/bin/mount`

END

}


backup() {

echo "Changing to /" ; pushd /
if [ $? -ne 0 ] ; then
	echo "Couldn't switch to / , exiting..."
	EXITSTAT=1
else
	/bin/mount |grep -Eq "\ on\ \/boot\ " && MBOOT=yes
	if [ "$MBOOT" != "yes" ] ; then
		echo "Mounting /boot"
		/bin/mount /boot
	fi
	echo "Starting /boot"
	/bin/tar zcvf $BAKBOOT -X $EXCLD /boot --one-file-system 2>&1 || BSTAT=$?
	echo "Starting /"
	/bin/tar zcvf $BAKROOT -X $EXCLD / --one-file-system 2>&1 || BSTAT=$?
	echo "Starting /home"
	/bin/tar zcvf $BAKHOME -X $EXCLD /home --one-file-system 2>&1 || BSTAT=$?
	echo "Starting /var"
	/bin/tar zcvf $BAKVAR -X $EXCLD /var --one-file-system 2>&1 || BSTAT=$?
	export BAKTIME=$((`/bin/date -u "+%s"` - $STARTTIME ))
	BAKDATE=`/bin/date -u -d "1970-01-01 $BAKTIME secs" +"%R:%S"`
	echo "Total Backup Time: $BAKDATE"
	echo
	if [ "$MBOOT" != "yes" ] ; then
		echo "Unmounting /boot"
		/bin/umount /boot
	fi
	if [ -n "$BSTAT" ] ; then
		echo "Backup seemed to fail :("
		echo "Exit status was: $BSTAT"
		false
	else
		echo "Backup completed OK"
		echo
		echo "Changing from root" ; popd
		rotate
	fi
	EXITSTAT=$?
	echo
	times
	echo

fi

return $EXITSTAT

}


rotate() {

cat << END
Removing stale archives:
Standard arachives over		$WARCHAGE days old
Monthly arachives over		$MARCHAGE days old

END

for t in log tgz ; do
/usr/bin/find ${BAKSTORE} -type f -mtime +${WARCHAGE} -name "${HOSTN}_full-sys_*.${t}" -exec rm -v {} \;
/usr/bin/find ${BAKSTORE} -type f -mtime +${MARCHAGE} -name "${HOSTN}_MONTHLY_*.${t}" -exec rm -v {} \;
done

}



header >> $LOG
backup >> $LOG

if [ $EXITSTAT -ne 0 ] ; then
	echo "Backup Failue"
	cat $LOG
fi

exit $EXITSTAT

#/bin/bash


#export DISPLAY=":0"
export HOME="/home/mythtv"
export MYTHCONFDIR="${HOME}/.mythtv"
#export NVCONF="${HOME}/.nvidia-settings-rc"
export MYTHPID="/var/run/myth-setup.pid"
export LIRCD="/dev/lircd"

#export MYTHSETUP_OPTS="--logpath /dev/null --syslog local7"

export QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb


/usr/bin/mythtv-setup $MYTHSETUP_OPTS



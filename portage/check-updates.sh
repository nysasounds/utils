#!/bin/bash
# Small script that syncs the portage tree and overlays then displays all updates

cat << END

Check updates now...  ...using $0


Syncing portage tree...

END

/usr/sbin/emaint sync -a

cat << END

Updating eix cache...

END

/usr/bin/eix-update

cat << END

Checking for possible updates...

END

/usr/bin/emerge -uDNpv @world --with-bdeps y


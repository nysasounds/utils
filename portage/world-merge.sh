#!/bin/bash

SUCCESSMSG="Updates complete ok :-)"
ERRORMSG="Updates failed, please check the topmost build error or portage logs for details"


cat << END

Updating now...  ...using $0

Checking for updates now using default target \"world\"...

END


/usr/bin/emerge -uDNav @world --with-bdeps y && echo $SUCCESSMSG || echo $ERRORMSG


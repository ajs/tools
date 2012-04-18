#!/bin/bash

whenrun=$(date +%Y%m%d%H%M%S)
rundir="mirror-run-${whenrun}"
mkdir -p $rundir || exit 1
touch cookies.save || exit 1
wget --retry-connrefused -E --load-cookies cookies.save --save-cookies cookies.save --keep-session-cookies -U 'Mozilla/5.0 (compatible; keysmasher 1.0; www.ajs.com/keyspider)' --secure-protocol=auto --no-check-certificate --random-file=/dev/urandom -r -l 25 -N -T 20 -w 5 --waitretry 5 --random-wait -H -np -P "${rundir}" $*

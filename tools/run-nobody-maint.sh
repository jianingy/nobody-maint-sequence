#!/bin/sh

# BUILD ENVIRONMENT {{
which gpg || exit 111
root=/tmp/nobody-maint-sequence/
lock=$root/lock
mkdir -p $root
trap "rm -rf $root" 1 2 15 EXIT
# }}

# TRY LOCK  {{
[ -f $lock ] && exit 0
echo $$ > $lock
[ "$(cat $lock)" != "$$" ] && exit 0
# }} LOCK ACQUIRED
HOME=$root
hostname=$(hostname -f)
gpgkey=GPGKEY_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export RSYNC_PASSWORD=RSYNC_PASSWORD_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
gpg --list-keys $gpgkey || gpg --recv-keys $gpgkey
rsync -a nobody@SERVER::nobody-maint-sequence $root
pushd $root >/dev/null || exit 1
exec 3>$hostname.status
exec 4>$hostname.stdout
exec 5>$hostname.stderr
FAILED=0
echo >&3 "# $hostname $(date)"
echo >&4 "# $hostname $(date)"
echo >&5 "# $hostname $(date)"
for asc in *.asc; do
	bin=$(echo $asc | sed -e 's/\.asc$//')
	if gpg --verify $asc 2>/dev/null; then
		chmod +x ./$bin
		if ./$bin 1>&4 2>&5; then
		   echo >&3 "$bin: OK"
		else
		   echo >&3 "$bin: FAILED"
		   FAILED=1
		fi
	else
		echo >&3 "$bin: BROKEN"
	fi
done
popd >/dev/null

#!/bin/bash

/bin/bash /root/rq-acquire.sh > /var/run/rq_acquired
SENTRY_IDENTIFIER=${SENTRY_IDENTIFIER:-$(cat /var/run/rq_acquired)}

function cleanup() {
	/bin/sh /root/rq-release.sh `cat /var/run/rq_acquired`
	if [ -n "$TAIL_PID" ]; then
		kill $TAIL_PID
	fi
}

trap cleanup EXIT SIGTERM SIGINT

if [ ! -d /opt/logpresso-sentry ]; then
	. /root/install-docker.sh
	#rm -f /root/install-docker.sh
fi

tail -F /opt/logpresso-sentry/log/araqne.log &
TAIL_PID=$!

/opt/logpresso-sentry/logpresso start

function check_status() {
	/opt/logpresso-sentry/logpresso status > /dev/null 2>&1
	return $?
}

while check_status; do sleep 1; done

## always restarted by k8s restartPolicy: Always
exit 1
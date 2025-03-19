#!/bin/bash

function cleanup() {
	/opt/logpresso-sentry/logpresso stop
	if [ -n "$TAIL_PID" ]; then
		kill $TAIL_PID
	fi
}

trap cleanup EXIT SIGTERM SIGINT

if [ ! -e /opt/logpresso-sentry/data ]; then
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
#!/bin/bash

# This script is used to start the Logpresso Sentry daemon.
# It is used to monitor the Logpresso Sentry daemon and restart it if it crashes.
# When the container starts, it loads settings from the sonar-sentry-daemonset configmap,
# then attempts to register the sentry and create collectors based on those settings.

function cleanup() {
	/opt/logpresso-sentry/logpresso stop
	if [ -n "$TAIL_PID" ]; then
		kill $TAIL_PID
	fi
}

trap cleanup EXIT SIGTERM SIGINT

if [ ! -e /opt/logpresso-sentry/data ]; then
	. /root/install-docker.sh
	
	# 센트리 등록 시도
	/opt/logpresso-sentry/bin/register-sentry.sh
	
	# 수집기 생성 시도 
	/opt/logpresso-sentry/bin/create-collectors.sh
	
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
#!/bin/bash
if [ ! -d /opt/logpresso-sentry ]; then
	. /root/install-docker.sh
	#rm -f /root/install-docker.sh
fi

tail -F /opt/logpresso-sentry/log/araqne.log &
TAIL_PID=$!
trap "kill $TAIL_PID" EXIT

/opt/logpresso-sentry/logpresso start

function check_status() {
	/opt/logpresso-sentry/logpresso status > /dev/null 2>&1
	return $?
}

while check_status; do sleep 1; done

## always restarted by k8s restartPolicy: Always
exit 1
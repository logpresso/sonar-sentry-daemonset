if [ -e /var/run/rq_acquired ]; then
    /bin/sh /root/rq-release.sh `cat /var/run/rq_acquired`
    if [ $? -eq 0 ]; then
		rm /var/run/rc_acquired
	fi
fi
/bin/sh -c /opt/logpresso-sentry/logpresso stop
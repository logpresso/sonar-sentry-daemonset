#!/bin/bash

# 이 프로그램은 센트리의 초기 설치시 install-docker.sh 에서 호출되며, 
# 센트리 등록 및 수집기 생성을 시도한다.
# 생성해야 할 수집기의 설정은 sonar-sentry-daemonset/values.yaml 의 sonar.loggers 에 정의되어 있다.
# 해당 설정을 configmap 에서 읽어와서 수집기 생성 루프를 수행한다. 

SENTRY_IDENTIFIER=${SENTRY_IDENTIFIER:-$(echo -n $K8S_NODE_NAME | sha1sum | cut -c 1-6)}
GUID=${SENTRY_GUID_PREFIX:-sonar-sentry-}$SENTRY_IDENTIFIER
TOKEN=${SENTRY_AUTH_TOKEN}
URL=$DEPLOY_URL
BASE=$BASE_ADDR
RPC_PORT=7140
CONF_FILE=logpresso.conf

if [ -n "$TOKEN" ]; then
	set -e
    echo "Public IP: `curl -s ifconfig.me`"
	#SONAR_API_KEY=${SONAR_API_KEY:-`cat /etc/secrets/sonar-api-key`}
	echo "Registering Daemonset Sentry..."
	API_TARGET=${DEPLOY_URL/:44300/:$CONTROL_API_PORT}/api/sonar/sentries
	echo GUID: $GUID
	echo API_TARGET: $API_TARGET
	RESPONSE=$(curl -s -k -X POST "$API_TARGET" \
		-d "sentry_guid=${GUID}&auth_token=${TOKEN}&os=linux&base=$BASE" \
		-H "Authorization: Bearer ${SONAR_API_KEY}")
	set +e
fi

#!/bin/bash

MAX_RETRIES=5
APISERVER=https://kubernetes.default.svc
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
TOKEN=$(cat ${SERVICEACCOUNT}/token)
CACERT=${SERVICEACCOUNT}/ca.crt

ID_PREFIX="sentry-"

get_available_id() {
    # 현재 사용 중인 ID 목록 가져오기
    USED_IDS=$(curl --silent --cacert ${CACERT} \
        --header "Authorization: Bearer ${TOKEN}" \
        ${APISERVER}/api/v1/namespaces/${NAMESPACE}/resourcequotas | \
        grep -o ${ID_PREFIX}'[0-9]\{3\}' | cut -d'-' -f2)
    
    # 001부터 999까지 순회하면서 사용 가능한 첫 번째 ID 찾기
    for i in $(seq -f "%03g" 1 999); do
        if ! echo "$USED_IDS" | grep -q "^${i}$"; then
            echo $i
            return 0
        fi
    done
    return 1
}

acquire_id() {
    NEXT_ID=$(get_available_id)
    if [ -z "$NEXT_ID" ]; then
        return 1
    fi

    RESPONSE=$(curl --silent --fail \
        --cacert ${CACERT} \
        --header "Authorization: Bearer ${TOKEN}" \
        -X POST ${APISERVER}/api/v1/namespaces/${NAMESPACE}/resourcequotas \
        -H 'Content-Type: application/json' \
        -d "{
            \"apiVersion\": \"v1\",
            \"kind\": \"ResourceQuota\",
            \"metadata\": {
                \"name\": \"${ID_PREFIX}${NEXT_ID}\",
                \"labels\": { \"created-by\": \"$(cat /etc/hostname)\" }
            },
            \"spec\": {
                \"hard\": {
                    \"id-pool.custom.io/used\": \"1\"
                }
            }
        }")
    
    if [ $? -eq 0 ]; then
        echo $NEXT_ID
        return 0
    fi
    return 1
}

for ((try=1; try<=MAX_RETRIES; try++)); do
    ACQUIRED_ID=$(acquire_id)
    if [ $? -eq 0 ]; then
        echo $ACQUIRED_ID
        exit 0
    fi
    sleep 1
done

echo "Failed to acquire ID after $MAX_RETRIES retries"
exit 1

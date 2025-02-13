#!/bin/bash

APISERVER=https://kubernetes.default.svc
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)
TOKEN=$(cat ${SERVICEACCOUNT}/token)
CACERT=${SERVICEACCOUNT}/ca.crt

ID_PREFIX="sentry-"

if [ -z "$1" ]; then
   echo "ACQUIRED_ID is required"
   exit 1
fi

ACQUIRED_ID=$1
echo "Releasing ${ID_PREFIX}${ACQUIRED_ID}..."

curl --silent --fail \
   --cacert ${CACERT} \
   --header "Authorization: Bearer ${TOKEN}" \
   -X DELETE \
   "${APISERVER}/api/v1/namespaces/${NAMESPACE}/resourcequotas/${ID_PREFIX}${ACQUIRED_ID}"

if [ $? -eq 0 ]; then
   echo "Successfully released ID: ${ACQUIRED_ID}"
   exit 0
else
   echo "Failed to release ID: ${ACQUIRED_ID}"
   exit 1
fi

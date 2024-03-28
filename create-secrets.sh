#!/bin/bash

# create-secrets.sh 및 secrets.yaml.tmpl 다운로드
curl -O https://lab.logpresso.com/sonar-sentry-daemonset/secrets.yaml.tmpl

SENTRY_AUTH_TOKEN=`tr -dc a-z0-9 </dev/urandom | head -c 4`-`tr -dc a-z0-9 </dev/urandom | head -c 4`
echo -n "Please enter your Sonar API Key: "
read -s SONAR_API_KEY

echo

cat secrets.yaml.tmpl > secrets.yaml
echo -n "  sentry-auth-token: " >> secrets.yaml
echo $SENTRY_AUTH_TOKEN | base64 >> secrets.yaml
echo -n "  sonar-api-key: " >> secrets.yaml
echo $SONAR_API_KEY | base64 >> secrets.yaml

kubectl apply -f secrets.yaml

rm secrets.yaml

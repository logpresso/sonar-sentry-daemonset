#!/bin/bash

echo -n "Please enter your Sonar API Key: "
read -s SONAR_API_KEY

echo

cat secrets.yaml.tmpl > secrets.yaml

echo Generated a random SENTRY_AUTH_TOKEN.
SENTRY_AUTH_TOKEN=`tr -dc a-z0-9 </dev/urandom | head -c 4`-`tr -dc a-z0-9 </dev/urandom | head -c 4`
echo -n "  SENTRY_AUTH_TOKEN: " >> secrets.yaml
echo -n $SENTRY_AUTH_TOKEN | base64 >> secrets.yaml
echo >> secrets.yaml
echo -n "  SONAR_API_KEY: " >> secrets.yaml
echo -n $SONAR_API_KEY | base64 >> secrets.yaml
echo >> secrets.yaml

echo secrets.yaml created.

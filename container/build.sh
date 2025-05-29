#!/bin/bash
#docker image rm sonar-sentry:latest sonar-sentry-debug:latest
VERSION=${1:-1.2.4}

echo $VERSION

docker build -t sonar-sentry:$VERSION .

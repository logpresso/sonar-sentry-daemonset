#!/bin/bash
#docker image rm sonar-sentry:latest sonar-sentry-debug:latest
VERSION=${1:-1.0.0}

echo $VERSION

docker build -t sonar-sentry:$VERSION .

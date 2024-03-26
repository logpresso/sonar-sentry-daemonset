#!/bin/bash
docker image rm sonar-sentry:latest sonar-sentry-debug:latest
docker build -t sonar-sentry:latest .

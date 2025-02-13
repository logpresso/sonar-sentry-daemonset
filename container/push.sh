#!/bin/bash
VERSION=${1:-1.1.0}
PUBLIC_REPO=public.ecr.aws/z5g1b4t8/sonar-sentry-dev

echo $VERSION

docker tag sonar-sentry:$VERSION $PUBLIC_REPO:$VERSION
docker push $PUBLIC_REPO:$VERSION 
 

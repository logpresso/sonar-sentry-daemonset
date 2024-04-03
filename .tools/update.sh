#!/bin/bash

set -e

if [ ! -f index.yaml ]; then
	echo "Error: Please execute this script from the directory where the index.yaml file is located."
	echo "ex) .tools/update.sh"
	exit 1
fi

CHART_DIR="../sonar-sentry-daemonset/helm-new/sonar-sentry-daemonset"
NAME=$(grep -E "^name:" $CHART_DIR/Chart.yaml | awk '{print $2}')
pushd $CHART_DIR

grep -E "^version:" Chart.yaml

echo -n "New version: "; read NEW_VERSION

# cp Chart.yaml Chart.yaml.original
sed -i "s/version:.*/version: $NEW_VERSION/" Chart.yaml

popd

mkdir tmp
pushd tmp

helm package ../$CHART_DIR

helm repo index --merge ../index.yaml .
mv index.yaml *.tgz ../
cp ../$CHART_DIR/README.md ..

popd
rm -rf tmp

git add README.md index.yaml *.tgz
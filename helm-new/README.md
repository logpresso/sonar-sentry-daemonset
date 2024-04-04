# Sonar Sentry DaemonSet Helm Chart

This Helm chart deploys the Sonar Sentry DaemonSet on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.14+
- Helm 3.1.0

## Installing Logpresso Sonar Sentry

```bash
helm repo add logpresso https://lab.logpresso.com/helm-charts
helm repo update logpresso

export SENTRY_AUTH_TOKEN=`tr -dc a-z0-9 </dev/urandom | head -c 4`-`tr -dc a-z0-9 </dev/urandom | head -c 4`
export SONAR_API_KEY="########-####-####-####-############"

helm install sonar-sentry-secrets logpresso/sonar-sentry-secrets \
    --set sonar.sentryAuthToken=$SENTRY_AUTH_TOKEN \
    --set sonar.sonarApiKey=$SONAR_API_KEY \
    -n default

helm show values logpresso/sentry-daemonset

# Create OWN values-TENANT.yaml using "sonar:" section from previous output
# You must override deployUrl, baseAddr

helm install TENANT logpresso/sentry-daemonset -f values-TENANT.yaml
```


## Uninstalling the Chart

```bash
helm uninstall TENANT

## Uninstalling Sentry Permanently
helm uninstall sonar-sentry-secrets
```

## Parameters

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `sonar.guidPrefix` | Prefix string for the Sentry guid. Use the Release Name when empty. | `""` |
| `sonar.guidSuffix` | Suffix string for the Sentry guid | `""` |
| `sonar.deployUrl` | URL to download JRE, Sentry Package from Sonar | `https://TENANT.logpresso.cloud:44300` |
| `sonar.baseAddr` | Address of the Sentry Base (usually NLB) | `TENANT.nlb.logpresso.cloud` |
| `sonar.secret.name` | Name of K8S secret store | `sonar-sentry-secrets` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`
# Sonar Sentry DaemonSet Helm Chart

This Helm chart deploys the Sonar Sentry DaemonSet on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.14+
- Helm 3.1.0

## Installing the Chart

To install the chart with the release name `SITENAME-sentry`:

```bash
helm repo add logpresso https://lab.logpresso.com/sonar-sentry-daemonset
helm repo update logpresso

helm show values logpresso/sentry-daemonset

# Create OWN values-TENANT.yaml using "sonar:" section from previous output
# You must override deployUrl, baseAddr

helm install TENANT-sentry logpresso/sentry-daemonset -f values-TENANT.yaml
```


## Uninstalling the Chart

To uninstall/delete the `TENANT-sentry` deployment:

```bash
helm delete TENANT-sentry
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `sonar.guidPrefix` | Prefix string for the Sentry guid. Use the Release Name when empty. | `""` |
| `sonar.guidSuffix` | Suffix string for the Sentry guid | `""` |
| `sonar.deployUrl` | URL to download JRE, Sentry Package from Sonar | `https://TENANT.logpresso.cloud:44300` |
| `sonar.baseAddr` | Address of the Sentry Base (usually NLB) | `TENANT.nlb.logpresso.cloud` |
| `sonar.secret.name` | Name of K8S secret store | `sentry-secrets` |
| `sonar.secret.namespace` | Namespace of Node labels for pod assignment | `default` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`
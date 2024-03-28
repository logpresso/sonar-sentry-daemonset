# Sonar Sentry DaemonSet Helm Chart

This Helm chart deploys the Sonar Sentry DaemonSet on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0

## Installing the Chart

To install the chart with the release name `SITENAME-sentry`:

```bash
helm repo add logpresso https://lab.logpresso.com/sonar-sentry-daemonset
helm repo update
helm install SITENAME-sentry logpresso/sonar-sentry-daemonset

curl -sSL https://lab.logpresso.com/sonar-sentry-daemonset/create-secrets.sh | bash
```


## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```bash
helm delete my-release
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

| Parameter | Description | Default |
| --------- | ----------- | ------- |
| `serviceAccount.create` | Specifies whether a service account should be created | `true` |
| `serviceAccount.name` | The name of the service account to use | `""` |
| `podAnnotations` | Additional annotations to add to the pod | `{}` |
| `podLabels` | Additional labels to add to the pod | `{}` |
| `resources` | CPU/Memory resource requests/limits | `{}` |
| `nodeSelector` | Node labels for pod assignment | `{}` |
| `tolerations` | List of node taints to tolerate | `[]` |
| `affinity` | Map of node/pod affinities | `{}` |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```bash
helm install my-release logpresso/sonar-sentry-daemonset --set image.pullPolicy=Always
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
helm install my-release logpresso/sonar-sentry-daemonset -f values.yaml
```

# Helm chart prototype for Sonar Sentry Daemonset

- headless

## How to use

### Requirements

register [container](../../container) to your K8S container registry first.

### Deploy and Install

```
git clone https://github.com/logpresso/sonar-sentry-daemonset
cd sonar-sentry-daemonset
vim values.yaml # edit env section for your new sentry configuration
helm install sonar-sentry .
```

### Diagnostics

```
kubectl exec -it `kubectl get pods -o name | grep -i sonar-sentry` -- /bin/bash
```


### uninstall

```
helm uninstall sonar-sentry
```

### Rocky 9 Pod for testing

```
kubectl apply -f rocky-pod.yaml
kubectl get pods
kubectl exec -it rocky-test-pod -- /bin/bash
```

```
echo "<14>Syslog for testing" | nc -u sonar-sentry 514
```

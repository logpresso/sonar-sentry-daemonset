# Sonar Sentry Daemonset

## Directory Structure

- `container/`: Contains the Dockerfile and scripts for building the Docker image.
- `helm-new/`: Contains the Helm chart for deploying the Sonar Sentry Daemonset.

## How to Use

### Testing
You can use the Rocky 9 Pod for testing:

```sh
kubectl apply -f helm/rocky-pod.yaml
kubectl get pods
kubectl exec -it rocky-test-pod -- /bin/bash
```

Then, you can send a test syslog message:
```sh
echo "<14>Syslog for testing" | nc -u sonar-sentry 514
```

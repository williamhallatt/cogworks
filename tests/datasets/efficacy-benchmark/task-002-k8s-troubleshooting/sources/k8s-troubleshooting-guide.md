# Kubernetes Pod Troubleshooting Guide

## Diagnostic Workflow

When a pod is failing, follow this systematic approach:

### 1. Check Pod Status

```bash
kubectl get pods
kubectl get pods -n <namespace> -o wide
```

Look for status indicators:
- **Pending**: Pod hasn't been scheduled (resource constraints, node selectors)
- **CrashLoopBackOff**: Container repeatedly crashing
- **ImagePullBackOff**: Cannot pull container image
- **Error**: Container exited with error
- **OOMKilled**: Out of memory

### 2. View Pod Events

```bash
kubectl describe pod <pod-name>
```

Key sections to check:
- **Events**: Shows recent pod lifecycle events
- **State**: Current and previous container states
- **Conditions**: Pod readiness and health
- **Resources**: CPU/memory requests and limits

### 3. Check Container Logs

```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Previous crashed container
kubectl logs <pod-name> -c <container-name>  # Multi-container pods
```

### 4. Interactive Debugging

```bash
kubectl exec -it <pod-name> -- /bin/sh
kubectl debug <pod-name> -it --image=busybox
```

## Common Issues and Fixes

### CrashLoopBackOff

**Causes**:
- Application crashes on startup
- Missing dependencies or configuration
- Insufficient resources
- Failed health checks

**Diagnosis**:
1. Check logs for application errors
2. Review environment variables
3. Check ConfigMap/Secret references
4. Verify resource limits

**Example Fix - Missing ConfigMap**:
```yaml
# Create the missing ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database.url: "postgresql://db:5432/myapp"
  log.level: "info"
```

```bash
kubectl apply -f configmap.yaml
kubectl rollout restart deployment/web-app
```

### OOMKilled

**Cause**: Container exceeded memory limits

**Diagnosis**:
```bash
kubectl describe pod <pod-name> | grep -A 5 "Last State"
# Look for: "Reason: OOMKilled"
```

**Fix**:
```yaml
spec:
  containers:
  - name: app
    resources:
      requests:
        memory: "256Mi"
      limits:
        memory: "512Mi"  # Increase this
```

### ImagePullBackOff

**Causes**:
- Image doesn't exist
- Registry authentication failure
- Network issues
- Typo in image name

**Diagnosis**:
```bash
kubectl describe pod <pod-name>
# Check Events for "Failed to pull image"
```

**Fix**:
```bash
# Check image name
kubectl get deployment <deployment-name> -o yaml | grep image:

# Create image pull secret if needed
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<username> \
  --docker-password=<password>
```

### Failed Health Checks

**Cause**: Liveness or readiness probe failing

**Diagnosis**:
```bash
kubectl describe pod <pod-name>
# Look for: "Liveness probe failed" or "Readiness probe failed"
```

**Fix**:
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30  # Increase startup time
  periodSeconds: 10
```

## Troubleshooting Decision Tree

1. **Check pod status**
   - Pending → Check node resources, scheduling constraints
   - ImagePullBackOff → Verify image name, registry auth
   - CrashLoopBackOff → Check logs and configuration
   - OOMKilled → Increase memory limits
   - Error → Check logs for application errors

2. **If CrashLoopBackOff**:
   - Check logs for error messages
   - Verify ConfigMaps/Secrets exist
   - Check environment variables
   - Verify persistent volume claims
   - Review resource requests/limits

3. **If configuration issue**:
   - Create missing ConfigMap/Secret
   - Update references in Deployment
   - Rollout restart

4. **If resource issue**:
   - Increase resource limits
   - Check node capacity
   - Consider horizontal scaling

## Best Practices

1. **Always check logs first**: `kubectl logs` provides immediate insight
2. **Use describe for context**: Events show the timeline of issues
3. **Check previous container**: Use `--previous` flag for crashed containers
4. **Verify dependencies**: ConfigMaps, Secrets, PVCs must exist before pod starts
5. **Resource limits**: Set appropriate limits to prevent OOMKilled
6. **Health checks**: Configure proper startup, liveness, and readiness probes

## Quick Reference

```bash
# Status overview
kubectl get pods -A --field-selector=status.phase!=Running

# Detailed diagnostics
kubectl describe pod <name>
kubectl logs <name> --previous --tail=50
kubectl get events --sort-by=.metadata.creationTimestamp

# Interactive debug
kubectl debug <name> -it --image=busybox --share-processes

# Resource usage
kubectl top pods
kubectl describe nodes
```

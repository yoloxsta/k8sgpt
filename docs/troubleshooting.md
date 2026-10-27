# Troubleshooting Guide for K8sGPT Lab

This guide covers common issues you might encounter when setting up and running K8sGPT with kind and Azure OpenAI.

## Table of Contents

1. [Docker and Kind Issues](#docker-and-kind-issues)
2. [Kubernetes Cluster Issues](#kubernetes-cluster-issues)
3. [Azure OpenAI Connection Issues](#azure-openai-connection-issues)
4. [K8sGPT Configuration Issues](#k8sgpt-configuration-issues)
5. [Analysis Issues](#analysis-issues)

---

## Docker and Kind Issues

### Docker is not running

**Symptoms:**
```
Cannot connect to the Docker daemon
```

**Solutions:**
- **Linux:** Run `sudo systemctl start docker`
- **Windows:** Open Docker Desktop and wait for it to start
- **macOS:** Open Docker Desktop and wait for it to start

### Kind cluster creation fails

**Symptoms:**
```
ERROR: failed to create cluster: ...
```

**Common causes and solutions:**

1. **Insufficient resources:**
   ```bash
   # Check Docker resources
   docker info | grep -i memory
   
   # Increase Docker memory (Docker Desktop: Settings > Resources)
   # Recommended: 8GB+ for kind cluster
   ```

2. **Port conflicts:**
   ```bash
   # Check if ports 80 or 443 are in use
   # Linux/macOS
   lsof -i :80
   lsof -i :443
   
   # Windows (PowerShell)
   netstat -ano | findstr :80
   netstat -ano | findstr :443
   ```

3. **Docker network issues:**
   ```bash
   # Reset Docker network
   docker network prune
   ```

### Kind cluster nodes not ready

**Symptoms:**
```
kubectl get nodes
NAME                     STATUS     NotReady
```

**Solutions:**
```bash
# Check node details
kubectl describe node <node-name>

# Check Docker container status
docker ps -a | grep kind

# View kind container logs
docker logs <kind-control-plane-container-id>

# Restart the cluster
kind delete cluster --name k8sgpt-lab
./scripts/create-cluster.sh
```

---

## Kubernetes Cluster Issues

### Pods stuck in Pending state

**Symptoms:**
```
kubectl get pods
NAME        READY   STATUS    RESTARTS   AGE
myapp-pod   0/1     Pending   0          5m
```

**Diagnostic commands:**
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check node resources
kubectl describe nodes

# Check available resources
kubectl top nodes
kubectl top pods
```

**Common causes:**
- Insufficient CPU/memory resources
- PersistentVolumeClaims not bound
- Node selectors/taints not satisfied

### Pods in CrashLoopBackOff

**Symptoms:**
```
NAME        READY   STATUS             RESTARTS   AGE
myapp-pod   0/1     CrashLoopBackOff   5          10m
```

**Diagnostic commands:**
```bash
# View pod logs
kubectl logs <pod-name> --previous

# Check pod events
kubectl describe pod <pod-name>

# Check exit code
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'
```

### Pods in ImagePullBackOff

**Symptoms:**
```
NAME        READY   STATUS             RESTARTS   AGE
myapp-pod   0/1     ImagePullBackOff   0          2m
```

**Diagnostic commands:**
```bash
# Check image pull error details
kubectl describe pod <pod-name>

# Verify image exists
docker pull <image-name>
```

**Common causes:**
- Image doesn't exist or wrong tag
- Private registry authentication missing
- Image pull rate limit exceeded (Docker Hub)

---

## Azure OpenAI Connection Issues

### Temperature Error with GPT-5

**Symptoms:**
```
Error: Unsupported value: 'temperature' does not support 0.7 with this model. Only the default (1) value is supported.
```

**Solution:**
GPT-5 and newer models only support temperature value of `1`.

```bash
# Edit K8sGPT config
nano ~/.config/k8sgpt/k8sgpt.yaml

# Set temperature to 1
temperature: 1

# Or recreate config with correct temperature
cat > ~/.config/k8sgpt/k8sgpt.yaml << 'EOF'
ai:
  providers:
    - name: azureopenai
      model: gpt-5
      baseurl: https://your-resource.openai.azure.com/
      engine: gpt-5
      temperature: 1
      password: YOUR-API-KEY
defaultprovider: azureopenai
EOF

k8sgpt analyze --explain
```

### Authentication errors

**Symptoms:**
```
Error: Access denied due to invalid subscription key or wrong API endpoint
```

**Solutions:**

1. **Verify API key:**
   ```bash
   # Test API key directly
   curl -X POST \
     "https://<your-resource>.openai.azure.com/openai/deployments/<deployment>/chat/completions?api-version=2024-02-15-preview" \
     -H "api-key: <your-api-key>" \
     -H "Content-Type: application/json" \
     -d '{
       "messages": [{"role": "user", "content": "Hello"}],
       "max_tokens": 50
     }'
   ```

2. **Check Azure OpenAI resource:**
   ```bash
   # Using Azure CLI
   az cognitiveservices account show \
     --name <your-resource> \
     --resource-group <your-rg>
   ```

3. **Verify API key hasn't expired:**
   - Go to Azure Portal → Azure OpenAI → Keys and Endpoint
   - Regenerate key if needed

4. **Re-authenticate K8sGPT:**
   ```bash
   # Remove existing provider
   k8sgpt auth remove -b azureopenai
   
   # Add again with correct credentials
   k8sgpt auth add \
     --backend azureopenai \
     --model gpt-4 \
     --baseurl https://<your-resource>.openai.azure.com/ \
     --engine gpt-4
   
   # When prompted, paste your API key
   
   # Set as default
   k8sgpt auth default --provider azureopenai
   ```

### Endpoint connection errors

**Symptoms:**
```
Error: Connection refused or timeout
```

**Solutions:**

1. **Verify endpoint URL:**
   - Correct format: `https://<resource-name>.openai.azure.com/`
   - No trailing paths needed for K8sGPT config

2. **Check network connectivity:**
   ```bash
   # Test connectivity
   ping <resource-name>.openai.azure.com
   
   # Check DNS resolution
   nslookup <resource-name>.openai.azure.com
   ```

3. **Azure VM network restrictions:**
   - Check NSG rules allow outbound HTTPS (443)
   - Check if private endpoint is required

### Model deployment not found

**Symptoms:**
```
Error: Deployment not found
```

**Solutions:**

1. **List deployments:**
   ```bash
   # Using Azure CLI
   az cognitiveservices account deployment list \
     --name <your-resource> \
     --resource-group <your-rg>
   ```

2. **Create deployment if missing:**
   - Go to Azure AI Studio → Deployments
   - Create a new deployment for your chosen model
   - Note the exact deployment name (case-sensitive)

3. **Verify deployment name in config:**
   ```bash
   # Check your K8sGPT config
   cat ~/.config/k8sgpt/k8sgpt.yaml
   
   # Ensure "engine" matches your deployment name exactly
   engine: gpt-4  # Must match deployment name in Azure
   ```

---

## K8sGPT Configuration Issues

### K8sGPT not finding issues

**Symptoms:**
```
k8sgpt analyze
No problems found
```

**Diagnostic steps:**

1. **Verify broken resources exist:**
   ```bash
   kubectl get pods,deployments,services --all-namespaces
   kubectl get events --sort-by='.lastTimestamp'
   ```

2. **Check K8sGPT analyzers:**
   ```bash
   k8sgpt list-analyzers
   
   # Enable additional analyzers
   k8sgpt integration activate
   ```

3. **Run with verbose output:**
   ```bash
   k8sgpt analyze --explain --output json
   ```

### K8sGPT auth configuration issues

**Symptoms:**
```
Error: No AI backend configured
Error: AI provider openai not specified in configuration
```

**Solutions:**

1. **List configured backends:**
   ```bash
   k8sgpt auth list
   ```

2. **Set default provider:**
   ```bash
   k8sgpt auth default --provider azureopenai
   ```

3. **Verify configuration file:**
   ```bash
   cat ~/.config/k8sgpt/k8sgpt.yaml
   
   # Should contain:
   # - azureopenai provider with password
   # - defaultprovider: azureopenai
   ```

4. **Re-configure if needed:**
   ```bash
   k8sgpt auth remove -b azureopenai
   k8sgpt auth add --backend azureopenai --model gpt-4 --baseurl https://your-resource.openai.azure.com/ --engine gpt-4
   k8sgpt auth default --provider azureopenai
   ```

---

## Analysis Issues

### Slow analysis response

**Symptoms:**
- Analysis takes > 30 seconds
- Timeouts during analysis

**Solutions:**

1. **Check Azure OpenAI region:**
   - Deploy in the same region as your VM for lower latency
   
2. **Use faster model:**
   - gpt-3.5-turbo is faster than gpt-4
   - Consider gpt-4-turbo for balance of speed and quality

3. **Filter analyzers:**
   ```bash
   # Only run specific analyzers
   k8sgpt analyze --analyzers pod,service
   ```

4. **Check network latency:**
   ```bash
   # Test latency to Azure OpenAI
   curl -w "Time: %{time_total}s\n" \
     -X POST \
     "https://<endpoint>/openai/deployments/<deployment>/chat/completions?api-version=2024-02-15-preview" \
     -H "api-key: <key>" \
     -H "Content-Type: application/json" \
     -d '{"messages":[{"role":"user","content":"test"}],"max_tokens":10}'
   ```

### Incorrect analysis results

**Symptoms:**
- K8sGPT provides incorrect explanations
- Missing important issues

**Solutions:**

1. **Check if issues actually exist:**
   ```bash
   kubectl describe <resource> <name>
   kubectl logs <pod-name>
   kubectl get events
   ```

2. **Use different AI model:**
   - GPT-4 provides better analysis than GPT-3.5
   - Update deployment_name in config

3. **Clear K8sGPT cache:**
   ```bash
   # K8sGPT caches results
   k8sgpt filters remove --all
   ```

---

## Quick Diagnostic Commands

### Full cluster health check

```bash
# Node status
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# All pod status across namespaces
kubectl get pods --all-namespaces -o wide

# Recent events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Storage
kubectl get pv,pvc --all-namespaces

# Services and endpoints
kubectl get svc,ep --all-namespaces
```

### Azure OpenAI connectivity test

```bash
# Set variables
ENDPOINT="https://<your-resource>.openai.azure.com/"
API_KEY="<your-api-key>"
DEPLOYMENT="<deployment-name>"

# Test request
curl -X POST \
  "${ENDPOINT}openai/deployments/${DEPLOYMENT}/chat/completions?api-version=2024-02-15-preview" \
  -H "api-key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello, this is a test"}],
    "max_tokens": 50
  }'
```

### K8sGPT configuration check

```bash
# View current config
cat ~/.config/k8sgpt/k8sgpt.yaml

# List providers
k8sgpt auth list

# Test analysis
k8sgpt analyze --explain

# Check analyzers
k8sgpt list-analyzers
```

---

## Getting Help

1. **K8sGPT Documentation:** https://docs.k8sgpt.ai/
2. **K8sGPT GitHub Issues:** https://github.com/k8sgpt-ai/k8sgpt/issues
3. **K8sGPT Discord:** https://discord.gg/k8sgpt
4. **Azure OpenAI Documentation:** https://learn.microsoft.com/azure/ai-services/openai/

---

## Reset Environment

If all else fails, start fresh:

```bash
# Delete and recreate cluster
./scripts/cleanup.sh
./scripts/create-cluster.sh

# Re-configure K8sGPT
./scripts/setup-k8sgpt.sh
```

---

## Common Error Messages Reference

| Error Message | Cause | Solution |
|--------------|-------|----------|
| `temperature does not support X with this model` | GPT-5 only supports temperature=1 | Set `temperature: 1` in config |
| `Access denied due to invalid subscription key` | Wrong API key or endpoint | Verify key and endpoint in Azure Portal |
| `AI provider openai not specified` | Default provider not set | Run `k8sgpt auth default --provider azureopenai` |
| `Deployment not found` | Wrong deployment name | Check deployment name in Azure AI Studio |
| `No problems found` | No issues in cluster | Deploy broken workloads with `kubectl apply -f manifests/` |
| `Cannot connect to Docker daemon` | Docker not running | Start Docker Desktop or systemd service |

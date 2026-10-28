# K8sGPT Lab: AI-Powered Kubernetes Troubleshooting with Kind and Ollama

*Complete guide to setting up a free, offline K8sGPT lab on Azure VM*

## Introduction

K8sGPT is a tool for scanning Kubernetes clusters, diagnosing and triaging issues in simple English. It combines SRE experience codified into analyzers with AI to provide intelligent troubleshooting.

In this tutorial, you'll learn how to:
- Set up a local Kubernetes cluster using Kind
- Deploy K8sGPT for cluster analysis
- Use **Ollama** for free, offline AI-powered analysis (no API keys needed!)
- Optionally configure Azure OpenAI for cloud-based AI

## Why This Lab?

| Feature | Benefit |
|---------|---------|
| **100% Free** | No API costs with Ollama |
| **Offline** | Works without internet after setup |
| **Private** | Data never leaves your VM |
| **Fast** | Local processing with llama3.2 |
| **Simple** | No complex configuration |

## Architecture

```
Azure VM (Ubuntu 22.04)
├── Docker
├── Kind (3-node Kubernetes cluster)
├── Ollama (Local LLM server)
│   └── llama3.2 (3B parameter model)
└── K8sGPT CLI
    └── Analyzes cluster with AI
```

## Prerequisites

### Azure VM Requirements
- **OS**: Ubuntu 20.04/22.04 LTS
- **Size**: Standard_D2s_v3 or larger (2 vCPUs, 8GB RAM)
- **Storage**: 50GB+ SSD
- **Networking**: Outbound internet for initial setup

### For Ollama (Recommended)
- 4GB+ free RAM
- No GPU required (CPU-only mode works fine)

### For Azure OpenAI (Optional)
- Azure OpenAI resource
- API key and endpoint

## Step 1: Prepare Azure VM

### 1.1 Create Azure VM

```bash
# Using Azure CLI
az group create --name k8sgpt-lab --location eastus

az vm create \
  --resource-group k8sgpt-lab \
  --name k8sgpt-vm \
  --image Ubuntu2204 \
  --size Standard_D2s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys
```

### 1.2 SSH into VM

```bash
ssh azureuser@<vm-public-ip>
```

### 1.3 Clone the Lab Repository

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/k8sgpt-lab.git
cd k8sgpt-lab
```

Or create the directory structure manually:

```bash
mkdir -p ~/k8sgpt-lab/{config,scripts,manifests}
cd ~/k8sgpt-lab
```

## Step 2: Install Prerequisites

Run the automated setup script:

```bash
chmod +x scripts/setup-vm-linux.sh
sudo ./scripts/setup-vm-linux.sh
```

**What this installs:**
- Docker (container runtime)
- kubectl (Kubernetes CLI)
- kind (local Kubernetes)
- K8sGPT (cluster analysis tool)

**Important:** After the script completes, apply Docker group changes:

```bash
newgrp docker
```

### Manual Installation (Alternative)

If you prefer manual installation:

```bash
# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
sudo chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install K8sGPT
curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.48/k8sgpt_amd64.deb
sudo dpkg -i k8sgpt_amd64.deb
```

## Step 3: Create Kind Cluster

### 3.1 Create Cluster Configuration

```bash
cat > ~/k8sgpt-lab/config/kind-cluster.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: k8sgpt-lab
nodes:
  - role: control-plane
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker
  - role: worker
EOF
```

### 3.2 Create the Cluster

```bash
kind create cluster --config ~/k8sgpt-lab/config/kind-cluster.yaml
```

Expected output:
```
Creating cluster "k8sgpt-lab" ...
 ✓ Ensuring node image (kindest/node:v1.29.2) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-k8sgpt-lab"
```

### 3.3 Verify Cluster

```bash
kubectl get nodes
```

Expected output:
```
NAME                       STATUS   ROLES           AGE   VERSION
k8sgpt-lab-control-plane   Ready    control-plane   2m    v1.29.2
k8sgpt-lab-worker          Ready    <none>          90s   v1.29.2
k8sgpt-lab-worker2         Ready    <none>          90s   v1.29.2
```

## Step 4: Set Up AI Backend

You have two options: **Ollama** (free, offline) or **Azure OpenAI** (cloud-based).

### Option A: Ollama (Recommended for Labs)

#### 4.1 Install Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

#### 4.2 Download a Model

```bash
# Download llama3.2 (3B parameters, fast and efficient)
ollama pull llama3.2
```

Other options:
- `codellama` - Better for code analysis
- `llama3.1:70b` - Larger, more capable (needs 40GB+ RAM)
- `mistral` - Good balance of speed and quality

#### 4.3 Configure K8sGPT with Ollama

```bash
# Add Ollama backend
k8sgpt auth add --backend ollama --model llama3.2

# Set as default provider
k8sgpt auth default --provider ollama

# Verify configuration
k8sgpt auth list
```

Expected output:
```
Default:
> ollama

Active:
> ollama
```

#### 4.4 Verify Ollama Config

The configuration is auto-generated at `~/.config/k8sgpt/k8sgpt.yaml`:

```bash
cat ~/.config/k8sgpt/k8sgpt.yaml
```

Should show:
```yaml
ai:
  providers:
    - name: ollama
      model: llama3.2
      temperature: 0.7
      topp: 0.5
      topk: 50
      maxtokens: 2048
defaultprovider: ollama
```

### Option B: Azure OpenAI (Cloud-Based)

#### 4.1 Create Azure OpenAI Resource

```bash
# Using Azure CLI
az cognitiveservices account create \
  --name k8sgpt-openai \
  --resource-group k8sgpt-lab \
  --kind OpenAI \
  --sku S0 \
  --location eastus
```

#### 4.2 Deploy a Model

1. Go to Azure Portal → Azure OpenAI → Go to Azure AI Studio
2. Deployments → Create new deployment
3. Select GPT-4 or GPT-3.5-turbo
4. Note the deployment name

#### 4.3 Get API Key and Endpoint

```bash
# Get endpoint
az cognitiveservices account show \
  --name k8sgpt-openai \
  --resource-group k8sgpt-lab \
  --query properties.endpoint \
  --output tsv

# Get API key
az cognitiveservices account keys list \
  --name k8sgpt-openai \
  --resource-group k8sgpt-lab \
  --query key1 \
  --output tsv
```

#### 4.4 Configure K8sGPT with Azure OpenAI

```bash
# Add Azure OpenAI backend
k8sgpt auth add \
  --backend azureopenai \
  --model gpt-4 \
  --baseurl https://YOUR-RESOURCE.openai.azure.com/ \
  --engine gpt-4

# When prompted, paste your API key

# Set as default
k8sgpt auth default --provider azureopenai
```

**Important for GPT-5:** Temperature must be set to `1`

```bash
cat > ~/.config/k8sgpt/k8sgpt.yaml << 'EOF'
ai:
  providers:
    - name: azureopenai
      model: gpt-5
      baseurl: https://YOUR-RESOURCE.openai.azure.com/
      engine: gpt-5
      temperature: 1
      password: YOUR-API-KEY
defaultprovider: azureopenai
EOF
```

## Step 5: Deploy Test Workloads

### 5.1 Create Broken Deployment

```bash
cat > ~/k8sgpt-lab/manifests/broken-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: broken-app
  template:
    metadata:
      labels:
        app: broken-app
    spec:
      containers:
      - name: app
        image: nginx:nonexistent-tag-v99.99.99
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "1Mi"
            cpu: "1m"
          limits:
            memory: "2Mi"
            cpu: "2m"
EOF

kubectl apply -f ~/k8sgpt-lab/manifests/broken-deployment.yaml
```

### 5.2 Create Broken Service

```bash
cat > ~/k8sgpt-lab/manifests/broken-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: broken-service
  namespace: default
spec:
  selector:
    app: nonexistent
  ports:
  - port: 80
    targetPort: 8080
EOF

kubectl apply -f ~/k8sgpt-lab/manifests/broken-service.yaml
```

### 5.3 Wait for Issues to Appear

```bash
sleep 10
kubectl get pods
```

You should see pods in error states.

## Step 6: Run K8sGPT Analysis

### 6.1 Basic Analysis

```bash
k8sgpt analyze
```

Output:
```
0: Pod default/broken-app-858cc9ffdd-q66k8(Deployment/broken-app)
- Error: Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create containerd task...

1: Pod default/broken-app-858cc9ffdd-sxzfr(Deployment/broken-app)
- Error: Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create containerd task...
```

### 6.2 AI-Powered Explanations

```bash
k8sgpt analyze --explain
```

Output with Ollama:
```
AI Provider: ollama

0: Pod default/broken-app-858cc9ffdd-q66k8(Deployment/broken-app)
- Error: Failed to create pod sandbox: container init was OOM-killed (memory limit too low?)

Error: Failed to create pod sandbox due to OOM-killed container init.

Solution:
1. Check pod memory limits.
2. Increase pod memory limits using `--memory` flag.
3. Verify container resource requirements.
4. Adjust container resource limits using `--resources` flag.

1: Service default/broken-service()
- Error: Service has no endpoints, expected label app=nonexistent

Error: Service has no endpoints, expected label app=nonexistent

Solution:
1. Check if the service is correctly deployed.
2. Verify if the app label is correctly set in the service definition.
3. Run `kubectl get svc -l app=<app-name>` to check if the label is present.
```

### 6.3 JSON Output

```bash
k8sgpt analyze --output json
```

Useful for automation and CI/CD integration.

### 6.4 Filter by Namespace

```bash
k8sgpt analyze --namespace default --explain
```

### 6.5 Filter by Resource Type

```bash
k8sgpt analyze --analyzers pod,service --explain
```

## Step 7: Understanding K8sGPT Analyzers

K8sGPT has built-in analyzers for common Kubernetes resources:

```bash
k8sgpt list-analyzers
```

Available analyzers:
- `pod` - Pod status and events
- `service` - Service and endpoint issues
- `deployment` - Deployment rollout problems
- `pvc` - PersistentVolumeClaim issues
- `ingress` - Ingress misconfigurations
- `hpa` - Horizontal Pod Autoscaler problems
- `cronjob` - CronJob failures
- `networkpolicy` - Network policy issues
- And more...

## Step 8: Troubleshooting

### K8sGPT Installation Issues

**Problem:** `gzip: stdin: not in gzip format`

**Solution:** Use DEB package instead:
```bash
curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.48/k8sgpt_amd64.deb
sudo dpkg -i k8sgpt_amd64.deb
```

### Docker Permission Issues

**Problem:** `permission denied while trying to connect to the Docker daemon`

**Solution:** Add user to docker group:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Kind Cluster Issues

**Problem:** Cluster creation fails

**Solutions:**
1. Check Docker is running: `systemctl status docker`
2. Check available resources: `free -h`
3. Clean up and retry: `kind delete cluster --name k8sgpt-lab`

### Memory Issues

**Problem:** VM runs out of memory (3.7GB RAM is insufficient)

**Symptoms:**
```bash
$ free -h
               total        used        free      shared  buff/cache   available
Mem:           3.7Gi       3.6Gi       103Mi        29Mi       351Mi       181Mi
Swap:             0B          0B          0B
```

**Root Cause:** 
- Kind cluster: ~1.5 GB
- Ollama (llama3.2): ~2 GB
- K8sGPT: ~100 MB
- System: ~500 MB
- **Total needed: ~4 GB** (VM only has 3.7 GB)

**Solutions:**

**Option 1: Add Swap Space (Recommended)**

```bash
# Check disk space first
df -h

# Create 2-4GB swap file
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

Expected result:
```
               total        used        free      shared  buff/cache   available
Mem:           3.7Gi       1.2Gi       2.3Gi        37Mi       469Mi       2.5Gi
Swap:          3.6Gi          0B       3.6Gi
```

**Option 2: Stop Ollama When Not in Use**

```bash
# Stop Ollama (saves ~2GB RAM)
sudo systemctl stop ollama

# Start only when analyzing
sudo systemctl start ollama
k8sgpt analyze --explain

# Stop again
sudo systemctl stop ollama
```

**Option 3: Use Smaller Model**

```bash
# Remove large model
ollama rm llama3.2

# Use smaller model (1.5GB instead of 2GB)
ollama pull phi3

# Update K8sGPT
k8sgpt auth remove -b ollama
k8sgpt auth add --backend ollama --model phi3
k8sgpt auth default --provider ollama
```

**Option 4: Upgrade VM Size (Permanent Fix)**

```bash
# Stop VM
az vm deallocate --resource-group k8sgpt-lab --name k8sgpt-vm

# Resize to 8GB RAM
az vm resize --resource-group k8sgpt-lab --name k8sgpt-vm --size Standard_D4s_v3

# Start VM
az vm start --resource-group k8sgpt-lab --name k8sgpt-vm
```

**Memory Management Best Practices:**

```bash
# Monitor memory in real-time
watch -n 1 free -h

# Check what's using memory
htop

# Clean up Docker (if disk is also full)
docker system prune -a -f --volumes

# Clean apt cache
sudo apt-get clean
sudo apt-get autoremove -y
```

**Recommended Configuration:**
- **Minimum:** 3.7GB RAM + 4GB swap
- **Recommended:** 8GB RAM (Standard_D4s_v3)
- **Optimal:** 16GB RAM for larger models

### Azure OpenAI Temperature Error

**Problem:** `temperature does not support 0.7 with this model`

**Solution:** For GPT-5, set temperature to `1`:
```bash
cat > ~/.config/k8sgpt/k8sgpt.yaml << 'EOF'
ai:
  providers:
    - name: azureopenai
      model: gpt-5
      temperature: 1
      password: YOUR-API-KEY
defaultprovider: azureopenai
EOF
```

## Cost Comparison

### Ollama (Free)
- **VM cost only:** ~$70-150/month (Standard_D2s_v3)
- **No API costs**
- **Unlimited usage**
- **Works offline**

### Azure OpenAI (Pay-per-use)
- **VM cost:** ~$70-150/month
- **GPT-4:** ~$0.03/1K input tokens, $0.06/1K output tokens
- **GPT-3.5-turbo:** ~$0.0005/1K input tokens, $0.0015/1K output tokens
- **Depends on usage frequency**

**Recommendation:** Use Ollama for labs and development, Azure OpenAI for production.

## Performance Comparison

| Metric | Ollama (llama3.2) | Azure OpenAI (GPT-4) |
|--------|-------------------|----------------------|
| **Setup** | Simple (1 command) | Complex (Azure Portal) |
| **Analysis Speed** | 4-6 it/min | 10-15 it/min |
| **Quality** | Good | Excellent |
| **Offline** | ✅ Yes | ❌ No |
| **Privacy** | ✅ 100% local | ❌ Cloud processing |
| **Cost** | ✅ Free | ❌ Pay per use |

## Advanced Usage

### K8sGPT Operator

Deploy K8sGPT as an in-cluster operator for continuous monitoring:

```bash
k8sgpt operator install
```

### Integration with Trivy

Add security scanning:

```bash
k8sgpt integration activate trivy
```

### Custom Analyzers

Create custom analyzers for your specific use cases.

### CI/CD Integration

Use JSON output for automated pipelines:

```bash
k8sgpt analyze --output json > analysis-report.json
```

## Cleanup

### Delete Test Workloads

```bash
kubectl delete -f ~/k8sgpt-lab/manifests/
```

### Delete Kind Cluster

```bash
kind delete cluster --name k8sgpt-lab
```

### Remove K8sGPT

```bash
sudo apt-get remove k8sgpt
```

### Remove Ollama

```bash
sudo systemctl stop ollama
sudo systemctl disable ollama
sudo rm -rf /usr/local/bin/ollama
```

### Delete Azure Resources

```bash
az group delete --name k8sgpt-lab --yes --no-wait
```

## Conclusion

You've successfully set up a K8sGPT lab with:
- ✅ Local Kubernetes cluster using Kind
- ✅ AI-powered cluster analysis
- ✅ Free, offline operation with Ollama
- ✅ Optional cloud-based AI with Azure OpenAI

### Key Takeaways

1. **Ollama is perfect for labs** - Free, private, and works offline
2. **K8sGPT provides intelligent troubleshooting** - Not just error messages, but solutions
3. **Kind is ideal for development** - Lightweight, fast cluster creation
4. **Azure OpenAI for production** - When you need the best AI quality

### Next Steps

- Explore more K8sGPT analyzers
- Integrate with your CI/CD pipeline
- Deploy K8sGPT operator for continuous monitoring
- Create custom analyzers for your workloads

## Resources

- [K8sGPT Documentation](https://docs.k8sgpt.ai/)
- [Ollama](https://ollama.com/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
- [K8sGPT GitHub](https://github.com/k8sgpt-ai/k8sgpt)

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Docker permission denied | `newgrp docker` |
| K8sGPT install fails | Use DEB package |
| Kind cluster fails | Check Docker and resources |
| Ollama out of memory | Use smaller model or bigger VM |
| Azure OpenAI temperature error | Set temperature to 1 |
| No issues found | Deploy broken workloads |

---

**Author:** Your Name  
**Date:** October 2026  
**Tags:** Kubernetes, K8sGPT, Ollama, Azure, AI, Troubleshooting  
**License:** MIT

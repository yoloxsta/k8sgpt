# K8sGPT Lab: Kind Cluster နဲ့ Ollama သုံးပြီး AI-Powered Kubernetes Troubleshooting

*Azure VM ပေါ်မှာ Free, Offline K8sGPT Lab တည်ဆောက်နည်း လမ်းညွှန်*

![K8sGPT Architecture](https://img.shields.io/badge/K8sGPT-0.3.48-blue) ![Ollama](https://img.shields.io/badge/Ollama-llama3.2-green) ![Kind](https://img.shields.io/badge/Kind-v0.22.0-orange)

## မာတိကာ

1. [အချက်အလက်များ](#အချက်အလက်များ)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Step-by-Step Setup](#step-by-step-setup)
5. [Troubleshooting](#troubleshooting)
6. [Cost Comparison](#cost-comparison)
7. [နိဂုံး](#နိဂုံး)

---

## အချက်အလက်များ

**K8sGPT** ဆိုတာ Kubernetes clusters တွေကို scan လုပ်ပြီး ပြဿနာတွေကို AI သုံးပြီး ရှင်းပြပေးတဲ့ tool တစ်ခုပါ။ ဒီ tutorial မှာ သင်လေ့လာမယ့်အရာတွေ:

- ✅ **Kind** သုံးပြီး local Kubernetes cluster တည်ဆောက်နည်း
- ✅ **K8sGPT** install လုပ်ပြီး cluster analysis လုပ်နည်း
- ✅ **Ollama** သုံးပြီး free, offline AI-powered analysis (API key မလိုပါ!)
- ✅ **Azure OpenAI** configuration (optional)
- ✅ **Real-world troubleshooting** နဲ့ solutions တွေ

### ဒီ Lab ကဘာကောင်းလဲ။

| Feature | Benefit |
|---------|---------|
| **၁၀၀% အခမဲ့** | API cost မရှိဘူး Ollama နဲ့ |
| **Offline အလုပ်လုပ်တယ်** | Setup ပြီးရင် internet မလိုပါ |
| **Private** | Data တွေ VM ကနေ အပြင်မသွားပါ |
| **မြန်တယ်** | Local processing with llama3.2 |
| **ရှင်းရှင်းလေး** | Complex configuration မလိုပါ |

---

## Architecture

```
Azure VM (Ubuntu 22.04)
├── Docker (Container Runtime)
├── Kind (3-node Kubernetes cluster)
│   ├── Control Plane
│   ├── Worker 1
│   └── Worker 2
├── Ollama (Local LLM Server)
│   └── llama3.2 (3B parameter model)
└── K8sGPT CLI
    └── Cluster analysis with AI
```

### Memory Requirements

| Component | RAM Usage |
|-----------|-----------|
| Kind cluster | ~1.5 GB |
| Ollama (llama3.2) | ~2.0 GB |
| K8sGPT | ~0.1 GB |
| System | ~0.5 GB |
| **Total** | **~4.0 GB** |

⚠️ **အရေးကြီး:** 3.7GB RAM VM မှာ Swap space ထည့်ရမယ် (နောက်မှာရှင်းပြထားတယ်)

---

## Prerequisites

### Azure VM Requirements

- **OS:** Ubuntu 20.04/22.04 LTS
- **Size:** Standard_D2s_v3 or larger (2 vCPUs, 8GB RAM recommended)
- **Storage:** 50GB+ SSD
- **Networking:** Setup အတွက် internet လိုပါမယ်

### Ollama အတွက် (Recommended)

- RAM 4GB+ free
- GPU မလိုပါ (CPU-only mode အလုပ်လုပ်တယ်)

### Azure OpenAI အတွက် (Optional)

- Azure OpenAI resource
- API key နဲ့ endpoint

---

## Step-by-Step Setup

### Step 1: Azure VM ပြင်ဆင်ခြင်း

#### 1.1 Azure VM ဖန်တီးခြင်း

```bash
# Azure CLI သုံးပြီး
az group create --name k8sgpt-lab --location eastus

az vm create \
  --resource-group k8sgpt-lab \
  --name k8sgpt-vm \
  --image Ubuntu2204 \
  --size Standard_D2s_v3 \
  --admin-username azureuser \
  --generate-ssh-keys
```

#### 1.2 VM ထဲ SSH ဝင်ခြင်း

```bash
ssh azureuser@<vm-public-ip>
```

#### 1.3 Lab Repository Clone လုပ်ခြင်း

```bash
git clone https://github.com/YOUR-USERNAME/k8sgpt-lab.git
cd k8sgpt-lab
```

သို့မဟုတ် manually create လုပ်မယ်:

```bash
mkdir -p ~/k8sgpt-lab/{config,scripts,manifests}
cd ~/k8sgpt-lab
```

---

### Step 2: Prerequisites Install လုပ်ခြင်း

#### Automated Setup Script သုံးမယ်:

```bash
chmod +x scripts/setup-vm-linux.sh
sudo ./scripts/setup-vm-linux.sh
```

**Install လုပ်တာတွေ:**
- Docker (container runtime)
- kubectl (Kubernetes CLI)
- kind (local Kubernetes)
- K8sGPT (cluster analysis tool)

#### ⚠️ အရေးကြီး: Docker Group Changes Apply လုပ်ပါ

Script ပြီးသွားရင် ဒီ command run ပါ:

```bash
newgrp docker
```

ဒါမှ Docker commands တွေ run လို့ရမှာပါ။

#### Manual Installation (Alternative)

Automated script မသုံးချင်ရင်:

```bash
# System update
sudo apt-get update && sudo apt-get upgrade -y

# Docker install
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# kubectl install
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# kind install
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
sudo chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# K8sGPT install (DEB package - more reliable)
curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.48/k8sgpt_amd64.deb
sudo dpkg -i k8sgpt_amd64.deb
```

---

### Step 3: Kind Cluster ဖန်တီးခြင်း

#### 3.1 Cluster Configuration File ဖန်တီးခြင်း

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

#### 3.2 Cluster ဖန်တီးခြင်း

```bash
kind create cluster --config ~/k8sgpt-lab/config/kind-cluster.yaml
```

**Expected Output:**
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

#### 3.3 Cluster Verify လုပ်ခြင်း

```bash
kubectl get nodes
```

**Expected Output:**
```
NAME                       STATUS   ROLES           AGE   VERSION
k8sgpt-lab-control-plane   Ready    control-plane   2m    v1.29.2
k8sgpt-lab-worker          Ready    <none>          90s   v1.29.2
k8sgpt-lab-worker2         Ready    <none>          90s   v1.29.2
```

---

### Step 4: AI Backend Setup

နှစ်မျိုးရှိပါတယ်: **Ollama** (free, offline) သို့မဟုတ် **Azure OpenAI** (cloud-based)။

#### Option A: Ollama (Recommended for Labs) 🌟

##### 4.1 Ollama Install လုပ်ခြင်း

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

##### 4.2 Model Download လုပ်ခြင်း

```bash
# llama3.2 download (3B parameters, မြန်တယ်နဲ့ efficient)
ollama pull llama3.2
```

**Alternative Models:**
- `codellama` - Code analysis အတွက် ပိုကောင်းတယ်
- `llama3.1:70b` - ကြီးမားတယ်၊ ပိုစွမ်းအားကောင်းတယ် (40GB+ RAM လိုတယ်)
- `mistral` - Speed နဲ့ quality balance ကောင်းတယ်

##### 4.3 K8sGPT Configuration with Ollama

```bash
# Ollama backend add လုပ်ခြင်း
k8sgpt auth add --backend ollama --model llama3.2

# Default provider အဖြစ် set လုပ်ခြင်း
k8sgpt auth default --provider ollama

# Verify
k8sgpt auth list
```

**Expected Output:**
```
Default:
> ollama

Active:
> ollama
```

##### 4.4 Configuration File Verify လုပ်ခြင်း

Auto-generated config file က `~/.config/k8sgpt/k8sgpt.yaml` မှာရှိပါမယ်:

```bash
cat ~/.config/k8sgpt/k8sgpt.yaml
```

**Output:**
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

**Note:** Ollama အတွက် configuration file က auto-generated ဖြစ်ပြီး manual create လုပ်စရာမလိုပါ။

---

#### Option B: Azure OpenAI (Cloud-Based) ☁️

##### 4.1 Azure OpenAI Resource ဖန်တီးခြင်း

```bash
# Azure CLI သုံးပြီး
az cognitiveservices account create \
  --name k8sgpt-openai \
  --resource-group k8sgpt-lab \
  --kind OpenAI \
  --sku S0 \
  --location eastus
```

##### 4.2 Model Deploy လုပ်ခြင်း

1. Azure Portal → Azure OpenAI → Go to Azure AI Studio သွားပါ
2. Deployments → Create new deployment ကို click ပါ
3. GPT-4 သို့မဟုတ် GPT-3.5-turbo ကို select လုပ်ပါ
4. Deployment name ကို note ထားပါ

##### 4.3 API Key နဲ့ Endpoint ရယူခြင်း

```bash
# Endpoint ရယူခြင်း
az cognitiveservices account show \
  --name k8sgpt-openai \
  --resource-group k8sgpt-lab \
  --query properties.endpoint \
  --output tsv

# API key ရယူခြင်း
az cognitiveservices account keys list \
  --name k8sgpt-openai \
  --resource-group k8sgpt-lab \
  --query key1 \
  --output tsv
```

##### 4.4 K8sGPT Configuration with Azure OpenAI

```bash
# Azure OpenAI backend add လုပ်ခြင်း
k8sgpt auth add \
  --backend azureopenai \
  --model gpt-4 \
  --baseurl https://YOUR-RESOURCE.openai.azure.com/ \
  --engine gpt-4

# Prompt ပေါ်လာရင် API key paste လုပ်ပါ

# Default provider အဖြစ် set လုပ်ခြင်း
k8sgpt auth default --provider azureopenai
```

##### ⚠️ GPT-5 အတွက် Temperature Setting

GPT-5 မှာ temperature value က **1** ဖြစ်ရမယ်:

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

---

### Step 5: Test Workloads Deploy လုပ်ခြင်း

#### 5.1 Broken Deployment ဖန်တီးခြင်း

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

#### 5.2 Broken Service ဖန်တီးခြင်း

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

#### 5.3 Issues ပေါ်လာရန် စောင့်ခြင်း

```bash
sleep 10
kubectl get pods
```

Pods တွေ error state မှာ တွေ့ရမယ်။

---

### Step 6: K8sGPT Analysis Run ခြင်း

#### 6.1 Basic Analysis

```bash
k8sgpt analyze
```

**Output:**
```
0: Pod default/broken-app-858cc9ffdd-q66k8(Deployment/broken-app)
- Error: Failed to create pod sandbox: rpc error: code = Unknown desc...

1: Pod default/broken-app-858cc9ffdd-sxzfr(Deployment/broken-app)
- Error: Failed to create pod sandbox: rpc error: code = Unknown desc...
```

#### 6.2 AI-Powered Explanations 🤖

```bash
k8sgpt analyze --explain
```

**Output with Ollama:**
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
```

#### 6.3 JSON Output

```bash
k8sgpt analyze --output json
```

Automation နဲ့ CI/CD integration အတွက် အသုံးဝင်တယ်။

#### 6.4 Filter by Namespace

```bash
k8sgpt analyze --namespace default --explain
```

#### 6.5 Filter by Resource Type

```bash
k8sgpt analyze --analyzers pod,service --explain
```

---

## Troubleshooting

### Issue 1: K8sGPT Installation Failed

**Problem:** `gzip: stdin: not in gzip format`

**Solution:** DEB package သုံးပါ:

```bash
curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.48/k8sgpt_amd64.deb
sudo dpkg -i k8sgpt_amd64.deb
```

---

### Issue 2: Docker Permission Denied

**Problem:** `permission denied while trying to connect to the Docker daemon`

**Solution:** Docker group ထဲ user add လုပ်ပါ:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

---

### Issue 3: Kind Cluster Creation Failed

**Problem:** Cluster creation အောင်မြင်မဲ့ မဟုတ်ပါ

**Solutions:**
1. Docker running မရှိရင်: `systemctl status docker`
2. Available resources စစ်ပါ: `free -h`
3. Clean up လုပ်ပြီး retry: `kind delete cluster --name k8sgpt-lab`

---

### Issue 4: Memory Issues (Critical) ⚠️

**Problem:** VM မှာ memory မလုံလောက်ပါ (3.7GB RAM က မလုံလောက်ပါ)

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
- K8sGPT: ~0.1 GB
- System: ~0.5 GB
- **Total needed: ~4 GB** (VM မှာ 3.7 GB ပဲရှိတယ်)

**Solution: Swap Space Add လုပ်ပါ**

```bash
# Disk space စစ်ပါ
df -h

# 2GB swap file ဖန်တီးပါ
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Permanent အဖြစ် သိမ်းပါ
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify လုပ်ပါ
free -h
```

**Expected Result:**
```
               total        used        free      shared  buff/cache   available
Mem:           3.7Gi       1.2Gi       2.3Gi        37Mi       469Mi       2.5Gi
Swap:          3.6Gi          0B       3.6Gi
```

**Swap ဆိုတာဘာလဲ။**

Swap ဆိုတာ **Hard Disk ပေါ်မှာ RAM လိုအသုံးပြုတဲ့နေရာ** ဖြစ်ပါတယ်။

```
RAM = သင့်ရဲ့ စားပွဲ (Desktop)
     - လက်ရှိအလုပ်လုပ်နေတဲ့ စာရွက်စာတမ်းတွေ ထားတယ်
     - မြန်မြန်ဆန်ဆန် ရှာနိုင်တယ်
     
Swap = ဘေးက ဖားသေနတ် (Filing Cabinet)
     - ခေတ္တသိမ်းထားတဲ့ စာရွက်စာတမ်းတွေ
     - RAM ပြည့်သွားရင် ဒီမှာ ရွှေ့ထားတယ်
     - RAM ထက်နှေးတယ် (ဒါပေမဲ့ လုံလောက်တယ်)
```

**Alternative Solutions:**

**Option 1: Ollama Stop လုပ်ခြင်း (2GB RAM ချွေတာ)**

```bash
# Ollama stop လုပ်ပါ
sudo systemctl stop ollama

# Analyze လုပ်တဲ့အခါမှ start လုပ်ပါ
sudo systemctl start ollama
k8sgpt analyze --explain

# ပြန် stop လုပ်ပါ
sudo systemctl stop ollama
```

**Option 2: Smaller Model သုံးခြင်း**

```bash
# Large model remove လုပ်ပါ
ollama rm llama3.2

# Smaller model download လုပ်ပါ (1.5GB instead of 2GB)
ollama pull phi3

# K8sGPT update လုပ်ပါ
k8sgpt auth remove -b ollama
k8sgpt auth add --backend ollama --model phi3
k8sgpt auth default --provider ollama
```

**Option 3: VM Resize လုပ်ခြင်း (Permanent Fix)**

```bash
# VM stop လုပ်ပါ
az vm deallocate --resource-group k8sgpt-lab --name k8sgpt-vm

# 8GB RAM အထိ resize လုပ်ပါ
az vm resize --resource-group k8sgpt-lab --name k8sgpt-vm --size Standard_D4s_v3

# VM start လုပ်ပါ
az vm start --resource-group k8sgpt-lab --name k8sgpt-vm
```

---

### Issue 5: Azure OpenAI Temperature Error

**Problem:** `temperature does not support 0.7 with this model`

**Solution:** GPT-5 အတွက် temperature ကို `1` set လုပ်ပါ:

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

---

## Cost Comparison

### Ollama (Free) 💰

- **VM cost only:** ~$70-150/month (Standard_D2s_v3)
- **API costs:** $0
- **Usage:** Unlimited
- **Offline:** ✅ Works without internet

### Azure OpenAI (Pay-per-use) 💸

- **VM cost:** ~$70-150/month
- **GPT-4:** ~$0.03/1K input tokens, $0.06/1K output tokens
- **GPT-3.5-turbo:** ~$0.0005/1K input tokens, $0.0015/1K output tokens
- **Depends on:** Usage frequency

**Recommendation:** Labs နဲ့ development အတွက် Ollama သုံးပါ။ Production အတွက် Azure OpenAI သုံးပါ။

---

## Performance Comparison

| Metric | Ollama (llama3.2) | Azure OpenAI (GPT-4) |
|--------|-------------------|----------------------|
| **Setup** | ရှင်းတယ် (command တစ်ခု) | ရှုပ်တယ် (Azure Portal) |
| **Analysis Speed** | 4-6 it/min | 10-15 it/min |
| **Quality** | ကောင်းတယ် | အကောင်းဆုံး |
| **Offline** | ✅ ရတယ် | ❌ မရပါ |
| **Privacy** | ✅ 100% local | ❌ Cloud processing |
| **Cost** | ✅ အခမဲ့ | ❅ တစ်ခါသုံး တစ်ခါပေး |

---

## Advanced Usage

### K8sGPT Operator

Continuous monitoring အတွက် K8sGPT ကို in-cluster operator အဖြစ် deploy လုပ်ပါ:

```bash
k8sgpt operator install
```

### Trivy Integration

Security scanning add လုပ်ပါ:

```bash
k8sgpt integration activate trivy
```

### CI/CD Integration

Automation အတွက် JSON output သုံးပါ:

```bash
k8sgpt analyze --output json > analysis-report.json
```

---

## Cleanup

### Test Workloads Delete လုပ်ခြင်း

```bash
kubectl delete -f ~/k8sgpt-lab/manifests/
```

### Kind Cluster Delete လုပ်ခြင်း

```bash
kind delete cluster --name k8sgpt-lab
```

### K8sGPT Remove လုပ်ခြင်း

```bash
sudo apt-get remove k8sgpt
```

### Ollama Remove လုပ်ခြင်း

```bash
sudo systemctl stop ollama
sudo systemctl disable ollama
sudo rm -rf /usr/local/bin/ollama
```

### Azure Resources Delete လုပ်ခြင်း

```bash
az group delete --name k8sgpt-lab --yes --no-wait
```

---

## နိဂုံး

သင် K8sGPT lab တစ်ခုကို အောင်မြင်စွာ setup လုပ်ပြီးပြီ:

- ✅ Kind သုံးပြီး local Kubernetes cluster
- ✅ AI-powered cluster analysis
- ✅ Ollama နဲ့ free, offline operation
- ✅ Azure OpenAI (optional cloud-based AI)

### Key Takeaways

1. **Ollama က labs အတွက် အကောင်းဆုံး** - Free, private, offline အလုပ်လုပ်တယ်
2. **K8sGPT က intelligent troubleshooting ပေးတယ်** - Error messages တစ်ခုတည်းမဟုတ်ဘဲ solutions တွေပါ
3. **Kind က development အတွက် ideal** - Lightweight, fast cluster creation
4. **Azure OpenAI က production အတွက်** - အကောင်းဆုံး AI quality လိုရင်

### Next Steps

- K8sGPT analyzers အများကြီး explore လုပ်ပါ
- CI/CD pipeline ထဲ integrate လုပ်ပါ
- Continuous monitoring အတွက် K8sGPT operator deploy လုပ်ပါ
- သင့် workloads အတွက် custom analyzers တွေ ဖန်တီးပါ

---

## Resources

- [K8sGPT Documentation](https://docs.k8sgpt.ai/)
- [Ollama](https://ollama.com/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
- [K8sGPT GitHub](https://github.com/k8sgpt-ai/k8sgpt)

---

## Quick Reference

| Issue | Solution |
|-------|----------|
| Docker permission denied | `newgrp docker` |
| K8sGPT install fails | DEB package သုံးပါ |
| Kind cluster fails | Docker နဲ့ resources စစ်ပါ |
| Out of memory | Swap space add လုပ်ပါ |
| Azure OpenAI temperature error | Temperature ကို 1 set လုပ်ပါ |
| No issues found | Broken workloads deploy လုပ်ပါ |

---

**Author:** [Your Name]  
**Published:** October 2026  
**Reading Time:** 15 minutes  
**Tags:** Kubernetes, K8sGPT, Ollama, Azure, AI, Troubleshooting, DevOps  
**License:** MIT

---

*ဒီ article က သင့်ကို ကူညီနိုင်မယ်လို့ မျှော်လင့်ပါတယ်! Questions ရှိရင် comment မှာ မေးနိုင်ပါတယ်။ 👇*

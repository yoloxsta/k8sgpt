## K8sGPT ဆိုတာဘာလဲ။

K8sGPT ဆိုတာ Kubernetes clusters တွေကို scan လုပ်ပြီး ပြဿနာတွေကို AI သုံးပြီး ရှင်းပြပေးတဲ့ tool တစ်ခုပါ။

နဂိုကတော့ error messages တွေကိုပဲ မြင်ရတယ်။ ဒါပေမဲ့ K8sGPT က errors တွေကို မဟုတ်ဘူး၊ solutions တွေပါ ပြောပြတယ်။

ဥပမာ - ဒီမျိုး error တစ်ခု တွေ့ရတယ်:
```
Error: Failed to create pod sandbox: container init was OOM-killed
```

K8sGPT က ဒီမျိုး ပြန်ဖြေပါတယ်:
```
Error: The container couldn't start; it was OOM-killed because its memory limit is too low.

Solution:
1. Check pod memory limits.
2. Increase pod memory limits.
3. Verify container resource requirements.
```

AI က ဘာဖြစ်တယ်၊ ဘယ်လိုဖြေရှင်းရမယ်ဆိုတာ ပြောပေးတယ်။

---

## Lab Setup စတင်ခြင်း

### Azure VM Creation

ပထမဆုံး Azure VM တစ်လုံး create လုပ်ခဲ့တယ်:

```bash
az vm create \
  --resource-group k8sgpt-lab \
  --name k8sgpt-vm \
  --image Ubuntu2204 \
  --size Standard_D2s_v3 \
  --admin-username azureuser
```

VM ရပြီ။ SSH ဝင်လိုက်တယ်။

```bash
ssh azureuser@<public-ip>
```

### Prerequisites Installation

Docker, kubectl, kind, K8sGPT - ဒီလေးခုလုံး လိုတယ်။ တစ်ခုချင်းစီ install လုပ်ခဲ့တယ်။


```bash
curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.48/k8sgpt_amd64.deb
sudo dpkg -i k8sgpt_amd64.deb
```

---

### Kind Cluster Creation

Cluster config file တစ်ခု ရေးခဲ့တယ်။ 3 nodes - control plane တစ်ခု၊ worker နှစ်ခု။

```bash
kind create cluster --config kind-cluster.yaml
```

Output က ဒါမျိုး ပေါ်လာတယ်:
```
Creating cluster "k8sgpt-lab" ...
 ✓ Ensuring node image (kindest/node:v1.29.2) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
```

အဲဒါ အောင်မြင်တယ်။ `kubectl get nodes` run တဲ့အခါ 3 nodes လုံး Ready state မှာ တွေ့ရတယ်။

---

## AI Backend Selection

ဒီနေရာမှာ ရွေးစရာနှစ်ခုရှိတယ် - Azure OpenAI (cloud) ဒါမှမဟုတ် Ollama (local)။

Azure OpenAI က quality အကောင်းဆုံး။ GPT-4 သုံးလို့ရတယ်။ ဒါပေမဲ့ cost ကုန်တယ်။ API key လိုတယ်။ Internet လိုတယ်။

Ollama ကတော့ free။ Local မှာ run တယ်။ Internet မလိုပါဘူး model download လုပ်ပြီးရင်။ ဒါပေမဲ့ VM resources လိုတယ်။

ကျွန်တော်ကတော့ Ollama ကိုပဲ ရွေးခဲ့တယ်။ "Free ပြီး offline အလုပ်လုပ်တယ်ဆိုရင် ပိုကောင်းတယ်" ထင်ခဲ့တယ်။

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.2
```

llama3.2 model က 3B parameters။ 2GB disk space ယူတယ်။ တကယ်တမ်းတော့ memory usage က ပိုများတယ်။

K8sGPT configuration:

```bash
k8sgpt auth add --backend ollama --model llama3.2
k8sgpt auth default --provider ollama
```

Configuration file က auto-generated ဖြစ်သွားတယ်။ Manual မလုပ်စရာကောင်းဘူး။

---

## Testing with Broken Workloads

K8sGPT ကို test လုပ်ဖို့ ပျက်နေတဲ့ deployments တွေ create လုပ်ခဲ့တယ်။

ပထမ deployment - မရှိတဲ့ image tag သုံးထားတယ်။ Memory limits ကလည်း အရမ်းနည်းတယ် (2Mi)။

ဒုတိယ service - မရှိတဲ့ app label ကို select လုပ်ထားတယ်။

```bash
kubectl apply -f broken-deployment.yaml
kubectl apply -f broken-service.yaml
```

Pods တွေ error state မှာ ကျနေခဲ့တယ်။

---

## The Memory Crisis

ဒီနေရာမှာတော့ ပြဿနာကြီး စတွေ့ခဲ့ရတယ်။

VM က crash ဖြစ်သွားတော့မယ်ပဲ ဖြစ်နေတယ်။ `free -h` run ကြည့်တယ်:

```
               total        used        free      shared  buff/cache   available
Mem:           3.7Gi       3.6Gi       103Mi        29Mi       351Mi       181Mi
Swap:             0B          0B          0B
```

RAM 103MB ပဲကျန်တော့တယ်။ System က crash ဖြစ်သွားတော့မယ်။

ကျွန်တော် တွေးမိတယ် - "ဘာဖြစ်လို့ ဒီလောက် memory ကုန်သလဲ။"

Calculate လုပ်ကြည့်တယ်:
- Kind cluster (3 nodes): ~1.5 GB
- Ollama (llama3.2): ~2.0 GB
- K8sGPT: ~0.1 GB
- System overhead: ~0.5 GB
- **Total: ~4.1 GB**

VM မှာတော့ 3.7GB ပဲရှိတယ်။ 

ဒါက memory မလုံလောက်ဘူး။

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

ဒါမှ အလုပ်လုပ်ခဲ့တယ်။ `free -h` run ကြည့်တော့:

```
               total        used        free      shared  buff/cache   available
Mem:           3.7Gi       1.2Gi       2.3Gi        37Mi       469Mi       2.5Gi
Swap:          3.6Gi          0B       3.6Gi
```

Memory situation က ပိုကောင်းသွားပြီ။ အခု total memory က 7.3GB (RAM 3.7GB + Swap 3.6GB) ရှိသွားပြီ။

---

## K8sGPT Analysis - Finally Working

အခုတော့ K8sGPT run လို့ရပြီ။

```bash
k8sgpt analyze --explain
```

Output က ဒါမျိုး ပေါ်လာတယ်:

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

K8sGPT က ပြဿနာတစ်ခုချင်းစီအတွက် ဘာဖြစ်တယ်၊ ဘယ်လိုဖြေရှင်းရမယ်ဆိုတာ ပြောပြတယ်။

Performance ကတော့ ကောင်းတယ် - 4-6 iterations per minute။ llama3.2 model က CPU-only mode မှာ run နေတောင် အဲဒီလောက် မြန်တယ်။

---

## Lessons Learned

### 1. VM Sizing Matters

3.7GB RAM က DevOps tools တွေ run ဖို့ မလုံလောက်ပါဘူး။ အထူးသဖြင့် AI models တွေ run မယ်ဆိုရင်။

**Recommendation:**
- **Minimum:** 4GB RAM + 4GB swap
- **Recommended:** 8GB RAM (Standard_D4s_v3)
- **Optimal:** 16GB RAM for larger AI models

### 2. Swap Space is Essential

RAM မလုံလောက်ရင် swap space က救命။ အဖြစ်မှန်က production မှာတော့ RAM ကိုပဲ ချဲ့သင့်တယ်။ ဒါပေမဲ့ development/lab environments တွေမှာတော့ swap က အသင့်တော်ဆုံးပါ။

### 3. Docker Group Changes Need Session Restart

`sudo usermod -aG docker $USER` run ပြီးရင် `newgrp docker` ဒါမှမဟုတ် logout/login လုပ်ရမယ်။ ဒါမှ Docker commands တွေ အလုပ်လုပ်မှာပါ။

### 4. Use DEB Package for K8sGPT

Tarball download ကတခါခါ corrupt ဖြစ်တယ်။ DEB package က ပိုယုံကြည်စိတ်ချရတယ်။

### 5. Ollama is Perfect for Labs

- Free (no API costs)
- Offline (works without internet)
- Private (data never leaves VM)
- Easy setup (one command)

---

## Cost Comparison

ကျွန်တော့် setup မှာ Ollama သုံးထားတယ်။ Azure OpenAI သုံးရင်တော့ ဘယ်လောက်ကုန်မလဲ။

**Ollama (My Setup):**
- VM cost: ~$70-150/month (Standard_D2s_v3)
- API costs: $0
- Total: ~$70-150/month
- Usage: Unlimited

**Azure OpenAI Alternative:**
- VM cost: ~$70-150/month
- GPT-4 API: ~$0.03-0.06 per 1K tokens
- Usage-based cost
- Monthly cost: Depends on frequency

တကယ်တမ်းတော့ K8sGPT analysis တစ်ခုက 1K-2K tokens ဝန်းကျင်ပဲသုံးတယ်။ ဒါဆိုရင်တော့ Azure OpenAI သုံးရင်လည်း တလကို $5-10 လောက်ပဲ cost ကုန်မယ်။ ဒါပေမဲ့ Ollama က အခမဲ့ဖြစ်နေသေးတယ်။

---

## Performance Comparison

| Metric | Ollama (llama3.2) | Azure OpenAI (GPT-4) |
|--------|-------------------|----------------------|
| Setup | Simple (one command) | Complex (Azure Portal) |
| Analysis Speed | 4-6 it/min | 10-15 it/min |
| Quality | Good | Excellent |
| Offline | ✅ Yes | ❌ No |
| Privacy | ✅ 100% local | ❌ Cloud processing |
| Cost | ✅ Free | ❅ Pay per use |

ကျွန်တော့်အတွက်တော့ Ollama က ပိုကောင်းတယ်။ Lab environment မှာ free ဖြစ်တယ်၊ offline အလုပ်လုပ်တယ်။ ဒါပေမဲ့ production မှာတော့ Azure OpenAI က quality အကောင်းဆုံးပါ။

---

## The Journey Ends

နောက်ဆုံးမှာတော့ K8sGPT lab တစ်ခု အောင်မြင်စွာ setup လုပ်ပြီးပြီ။

အခု ဒီ setup က:
- ✅ Kind cluster (3 nodes) running
- ✅ Ollama with llama3.2 model
- ✅ K8sGPT analyzing clusters with AI
- ✅ Free, offline, private

Memory issue တော့ ကြုံခဲ့ရတယ်။ ဒါပေမဲ့ swap space နဲ့ solve လုပ်လိုက်တယ်။

---

## What Would I Do Differently?

1. **Better VM sizing** - Standard_D4s_v3 (8GB RAM) ကိုပဲ စမှာပါ
2. **Add swap earlier** - Setup script ထဲမှာပဲ swap space creation ထည့်မှာပါ
3. **Monitor resources** - `htop` နဲ့ `free -h` ကို ပိုသုံးမှာပါ
4. **Document everything** - ဒီ article လိုပဲ အားလုံးကို note မှတ်မှာပါ

---

## Next Steps

ဒီ lab ကို နောက်ထပ် ဘာတွေ လုပ်လို့ရသလဲ:

1. **CI/CD Integration** - K8sGPT analysis results တွေကို JSON format နဲ့ automation pipelines တွေမှာ သုံးလို့ရတယ်
2. **Multiple AI Models** - codellama, mistral တို့ စတဲ့ တခြား models တွေ စမ်းကြည့်လို့ရတယ်
3. **K8sGPT Operator** - In-cluster continuous monitoring အတွက� operator deploy လုပ်လို့ရတယ်
4. **Custom Analyzers** - သင့် application အတွက် specific analyzers တွေ ရေးလို့ရတယ်

---

## Resources

ဒီ links တွေက ကျွန်တော့်အတွက် အသုံးဝင်ခဲ့တယ်:

- [K8sGPT Documentation](https://docs.k8sgpt.ai/)
- [Ollama](https://ollama.com/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [K8sGPT GitHub](https://github.com/k8sgpt-ai/k8sgpt)

---

## Quick Troubleshooting Reference

ဒီ table က ကျွန်တော် ကြုံခဲ့ရတဲ့ ပြဿနာတွေနဲ့ ဖြေရှင်းချက်တွေပါ:

| Problem | Solution |
|---------|----------|
| Docker permission denied | `newgrp docker` |
| K8sGPT install fails | Use DEB package |
| Out of memory (103Mi free) | Add 2-4GB swap space |
| Cluster creation slow | Check Docker resources |
| No issues found | Deploy broken workloads to test |

---

## နိဂုံး

ဒါက တကယ်ဖြစ်ခဲ့တဲ့ ပုံပြင်တစ်ပုဒ်ပါ။ Memory crisis ကြုံခဲ့ရတယ်။ Swap space နဲ့ solve လုပ်ခဲ့တယ်။ နောက်ဆုံးမှာတော့ K8sGPT lab တစ်ခု အောင်မြင်စွာ run နိုင်ခဲ့တယ်။

ဒီ article က သင့်ကို ကူညီနိုင်မယ်လို့ မျှော်လင့်ပါတယ်။ သင်လည်း K8sGPT lab တစ်ခု တည်ဆောက်ချင်ရင် ဒီ steps တွေ လိုက်လုပ်ကြည့်ပါ။ Memory issue ကြုံရင် swap space မိုးခေါ်ပါ။

Questions ရှိရင် comment မှာ မေးနိုင်ပါတယ်။

---

**Published:** October 2026  
**Reading Time:** 10 minutes  
**Tags:** Kubernetes, K8sGPT, Ollama, DevOps, Troubleshooting, AI

---

*ဒီ article က သင့်ကို ကူညီနိုင်မယ်လို့ မျှော်လင့်ပါတယ်! Clap 👏 တစ်ချက်နှိပ်ပေးပါ။ Follow လုပ်ပေးပါ။ နောက်ထပ် articles တွေအတွက်!*

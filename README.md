# K8sGPT Lab with Kind Cluster and Azure OpenAI

This lab provides a complete setup for running K8sGPT with a local kind cluster on an Azure VM, using Azure OpenAI as the AI backend.

## Architecture Overview

```
Azure VM (Linux/Windows)
├── Docker
├── kind cluster (local Kubernetes)
├── K8sGPT CLI / Operator
└── Azure OpenAI (cloud AI backend)
```

## Prerequisites

### Azure VM Requirements
- **OS**: Ubuntu 20.04/22.04 LTS or Windows Server 2019/2022
- **Size**: Standard_D2s_v3 or larger (2 vCPUs, 8GB RAM recommended)
- **Storage**: 50GB+ SSD
- **Networking**: Outbound internet access for Azure OpenAI API

### Azure OpenAI Requirements
- Azure OpenAI resource deployed in your subscription
- Model deployment (gpt-4, gpt-4-turbo, or gpt-5 recommended)
- API key and endpoint URL

## Quick Start

### 1. Prepare Azure VM

**Linux (Ubuntu):**
```bash
chmod +x scripts/setup-vm-linux.sh
./scripts/setup-vm-linux.sh
```

**Windows (PowerShell as Administrator):**
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\setup-vm-windows.ps1
```

### 2. Create Kind Cluster

```bash
# Linux/macOS
./scripts/create-cluster.sh

# Windows PowerShell
.\scripts\create-cluster.ps1
```

### 3. Configure Azure OpenAI

**Using the setup script (recommended):**
```bash
./scripts/setup-k8sgpt.sh
```

**Or manually:**
```bash
# Add Azure OpenAI provider
k8sgpt auth add \
  --backend azureopenai \
  --model gpt-4 \
  --baseurl https://<your-resource>.openai.azure.com/ \
  --engine gpt-4

# When prompted, enter your API key

# Set as default provider
k8sgpt auth default --provider azureopenai
```

**Important for GPT-5:** Temperature must be set to `1`

```bash
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
```

### 4. Test with Sample Workloads

```bash
# Deploy broken sample applications
kubectl apply -f manifests/

# Run K8sGPT analysis with AI explanations
k8sgpt analyze --explain
```

## Project Structure

```
k8sgpt-lab/
├── README.md                           # This file
├── config/
│   ├── kind-cluster.yaml              # Kind cluster configuration
│   └── k8sgpt-config.yaml.example     # K8sGPT config template
├── scripts/
│   ├── setup-vm-linux.sh              # Linux VM setup script
│   ├── setup-vm-windows.ps1           # Windows VM setup script
│   ├── create-cluster.sh              # Kind cluster creation (Linux)
│   ├── create-cluster.ps1             # Kind cluster creation (Windows)
│   ├── setup-k8sgpt.sh                # K8sGPT initialization (Linux)
│   ├── setup-k8sgpt.ps1               # K8sGPT initialization (Windows)
│   ├── cleanup.sh                     # Environment cleanup (Linux)
│   └── cleanup.ps1                    # Environment cleanup (Windows)
├── manifests/
│   ├── broken-deployment.yaml         # Intentionally broken deployment
│   ├── broken-service.yaml            # Service with issues
│   ├── broken-ingress.yaml            # Misconfigured ingress
│   └── broken-pvc.yaml                # Storage issues
└── docs/
    ├── azure-openai-setup.md          # Azure OpenAI setup guide
    └── troubleshooting.md             # Common issues and solutions
```

## K8sGPT Usage Examples

### Basic Analysis
```bash
# Analyze all namespaces
k8sgpt analyze

# Analyze specific namespace
k8sgpt analyze --namespace default

# Get detailed explanations (uses AI)
k8sgpt analyze --explain

# Output as JSON
k8sgpt analyze --output json
```

### Filter by Analyzers
```bash
# List available analyzers
k8sgpt list-analyzers

# Use specific analyzers
k8sgpt analyze --analyzers pod,pvc,service

# Exclude analyzers
k8sgpt analyze --exclude-analyzers hpa
```

### Integration Options
```bash
# Install K8sGPT operator in cluster
k8sgpt operator install

# Configure additional integrations
k8sgpt integration activate trivy
k8sgpt integration activate prometheus
```

## Azure OpenAI Configuration

### Required Information
1. **Endpoint**: `https://<your-resource>.openai.azure.com/`
2. **API Key**: Available in Azure Portal → Azure OpenAI → Keys and Endpoint
3. **Deployment Name**: The name you gave your model deployment
4. **API Version**: Use `2024-02-15-preview` or later

### Setting Up Azure OpenAI

**Using Azure Portal:**
1. Create Azure OpenAI resource
2. Go to Azure AI Studio → Deployments
3. Create deployment for GPT-4 or GPT-5
4. Copy endpoint and API key

**Using Azure CLI:**
```bash
az group create --name k8sgpt-lab --location eastus

az cognitiveservices account create \
  --name k8sgpt-openai \
  --resource-group k8sgpt-lab \
  --kind OpenAI \
  --sku S0 \
  --location eastus

az cognitiveservices account deployment create \
  --name k8sgpt-openai \
  --resource-group k8sgpt-lab \
  --deployment-name gpt-4 \
  --model-name gpt-4 \
  --model-version "latest" \
  --sku-capacity 30 \
  --sku-name "Standard"
```

### Important Temperature Settings

| Model | Supported Temperature Values |
|-------|------------------------------|
| GPT-5 and newer | `1` only |
| GPT-4, GPT-4-turbo | `0.0` to `2.0` |
| GPT-3.5-turbo | `0.0` to `2.0` |

**If you see error:** `temperature does not support X with this model`

**Solution:** Set temperature to `1` in your config file.

## Troubleshooting

### Common Issues

1. **Kind cluster fails to start**
   - Ensure Docker is running
   - Check available memory (need 4GB+ free)
   - Review Docker logs: `docker logs <container-id>`

2. **Azure OpenAI connection errors**
   - Verify endpoint URL is correct
   - Check API key validity
   - Ensure model deployment exists
   - For GPT-5, set temperature to `1`

3. **K8sGPT shows no results**
   - Verify kubeconfig points to kind cluster
   - Check if sample broken deployments are applied
   - Run `kubectl get pods --all-namespaces` to see issues

4. **Temperature error with GPT-5**
   - Set `temperature: 1` in `~/.config/k8sgpt/k8sgpt.yaml`

5. **Authentication errors**
   - Remove and re-add provider: `k8sgpt auth remove -b azureopenai`
   - Verify API key is correct
   - Set default provider: `k8sgpt auth default --provider azureopenai`

### Reset Environment

```bash
# Delete and recreate kind cluster
./scripts/cleanup.sh
./scripts/create-cluster.sh

# Re-configure K8sGPT
./scripts/setup-k8sgpt.sh
```

## Cost Considerations

- **Azure VM**: ~$70-150/month (Standard_D2s_v3, depending on region)
- **Azure OpenAI**: Pay per token usage
  - GPT-4: ~$0.03/1K input tokens, $0.06/1K output tokens
  - GPT-3.5-turbo: ~$0.0005/1K input tokens, $0.0015/1K output tokens
  - GPT-5: Check Azure Portal for current pricing
- **Kind cluster**: Free (local Docker)

## Security Notes

- Store API keys securely (use environment variables or Azure Key Vault)
- Limit Azure OpenAI access with managed identities or private endpoints
- Use network security groups to restrict VM access
- Clean up resources when not in use
- Rotate API keys regularly

## Example Output

```bash
$ k8sgpt analyze --explain

AI Provider: azureopenai

0: Pod default/broken-app-54c4fff7f9-mdq8b(Deployment/broken-app)

- Error: Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create containerd task: 
  failed to create shim task: OCI runtime create failed: runc create failed: unable to start container 
  process: container init was OOM-killed (memory limit too low?): unknown

Error: The container couldn't start; it was OOM-killed because its memory limit is too low or the node lacks free RAM.

Solution: 1) Raise memory requests/limits. 2) Lower app startup memory. 3) Ensure node has free RAM or 
scale/move pod. 4) Redeploy/restart.
```

## Additional Resources

- [K8sGPT Documentation](https://docs.k8sgpt.ai/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
- [K8sGPT GitHub](https://github.com/k8sgpt-ai/k8sgpt)

## License

This lab setup is provided for educational purposes. See individual tool licenses for production use.

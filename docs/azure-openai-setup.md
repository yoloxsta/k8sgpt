# Azure OpenAI Setup Guide for K8sGPT Lab

This guide walks you through setting up Azure OpenAI for use with K8sGPT.

## Prerequisites

- Azure subscription
- Azure CLI installed (optional, but recommended)
- Sufficient quota for Azure OpenAI

## Step 1: Create Azure OpenAI Resource

### Option A: Using Azure Portal

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Click "Create a resource" → search for "OpenAI"
3. Select "Azure OpenAI" and click "Create"
4. Fill in the details:
   - **Subscription:** Your subscription
   - **Resource Group:** Create new (e.g., `k8sgpt-lab`) or use existing
   - **Region:** Choose a region close to your VM (e.g., East US, West Europe, France Central)
   - **Name:** Unique name (e.g., `k8sgpt-openai-<your-initials>`)
   - **Pricing Tier:** Standard S0
5. Click "Review + submit" → "Create"
6. Wait for deployment to complete (2-5 minutes)

### Option B: Using Azure CLI

```bash
# Set variables
RESOURCE_GROUP="k8sgpt-lab"
LOCATION="eastus"
OPENAI_NAME="k8sgpt-openai-$(whoami)"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Create Azure OpenAI resource
az cognitiveservices account create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --kind OpenAI \
  --sku S0 \
  --location $LOCATION \
  --yes
```

## Step 2: Deploy a Model

### Option A: Using Azure AI Studio (Recommended)

1. Go to your Azure OpenAI resource in the portal
2. Click **"Go to Azure AI Studio"** or **"Explore" → "Azure AI Studio"**
3. This opens Azure AI Studio in a new tab
4. Click **"Deployments"** in the left menu
5. Click **"Create new deployment"** or **"Deploy base model"**
6. Select a model:
   - **gpt-4 or gpt-4-turbo:** Best quality for analysis
   - **gpt-3.5-turbo:** Faster and more economical
   - **gpt-5:** Latest model (temperature must be 1)
7. Configure deployment:
   - **Deployment name:** Choose a name (e.g., `gpt-4` or `gpt-5`)
   - **Deployment type:** Global Standard (recommended)
   - **Model version:** Use default/latest
   - **Tokens per minute (TPM):** Start with 30K-50K
   - **Content safety:** DefaultV2
8. Click **"Create"** or **"Deploy"**

### Option B: Using Azure CLI

```bash
# Deploy GPT-4 model
az cognitiveservices account deployment create \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --deployment-name gpt-4 \
  --model-name gpt-4 \
  --model-version "latest" \
  --sku-capacity 30 \
  --sku-name "Standard"
```

## Step 3: Get API Key and Endpoint

### Option A: Using Azure Portal

1. Go to your Azure OpenAI resource
2. Navigate to **"Keys and Endpoint"** in the left menu
3. Copy:
   - **KEY 1** or **KEY 2** (either works)
   - **Endpoint** URL (format: `https://<resource-name>.openai.azure.com/`)

### Option B: Using Azure CLI

```bash
# Get endpoint
az cognitiveservices account show \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.endpoint \
  --output tsv

# Get API key
az cognitiveservices account keys list \
  --name $OPENAI_NAME \
  --resource-group $RESOURCE_GROUP \
  --query key1 \
  --output tsv
```

## Step 4: Test Your Deployment

Test that your Azure OpenAI deployment is working:

```bash
# Set variables (replace with your values)
ENDPOINT="https://<your-resource>.openai.azure.com/"
API_KEY="<your-api-key>"
DEPLOYMENT="gpt-4"

# Test API call
curl -X POST \
  "${ENDPOINT}openai/deployments/${DEPLOYMENT}/chat/completions?api-version=2024-02-15-preview" \
  -H "api-key: ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello, are you working?"}],
    "max_tokens": 50
  }'
```

Expected response should include a completion from the model.

## Step 5: Configure K8sGPT

### Method 1: Using K8sGPT CLI (Recommended)

```bash
# Add Azure OpenAI provider
k8sgpt auth add \
  --backend azureopenai \
  --model gpt-4 \
  --baseurl https://<your-resource>.openai.azure.com/ \
  --engine gpt-4

# When prompted, paste your API key

# Set as default provider
k8sgpt auth default --provider azureopenai

# Verify configuration
k8sgpt auth list

# Test analysis
k8sgpt analyze --explain
```

### Method 2: Using Configuration File

Create or edit the K8sGPT config file:

```bash
cat > ~/.config/k8sgpt/k8sgpt.yaml << 'EOF'
ai:
  providers:
    - name: azureopenai
      model: gpt-4
      baseurl: https://<your-resource>.openai.azure.com/
      engine: gpt-4
      temperature: 1
      password: YOUR-API-KEY-HERE
defaultprovider: azureopenai
EOF
```

**IMPORTANT Temperature Settings:**
- **GPT-5 and newer models:** Temperature MUST be set to `1` (only supported value)
- **GPT-4 and GPT-3.5:** Temperature can be `0.0` to `2.0` (default: `1`)
- If you get error: "temperature does not support X with this model", set temperature to `1`

### Example Configuration for GPT-5

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

k8sgpt analyze --explain
```

## Cost Management

### Azure OpenAI Pricing (as of 2024)

**GPT-4 / GPT-4-turbo:**
- Input: ~$0.01-0.03 per 1K tokens
- Output: ~$0.03-0.06 per 1K tokens

**GPT-3.5-turbo:**
- Input: ~$0.0005 per 1K tokens
- Output: ~$0.0015 per 1K tokens

**GPT-5:**
- Check Azure Portal for current pricing

### Tips to Minimize Costs

1. **Use GPT-3.5-turbo for testing** - much cheaper
2. **Set appropriate TPM limits** - start with 30K-50K TPM
3. **Monitor usage** - Azure Portal → Azure OpenAI → Metrics
4. **Delete unused deployments** - you pay for provisioned capacity
5. **Use caching** - K8sGPT caches analysis results
6. **Use --no-cache sparingly** - only when needed for fresh analysis

## Troubleshooting

### "Insufficient quota" error

- Request quota increase in Azure Portal
- Use a different region with available capacity
- Use a smaller TPM limit

### "Deployment not found" error

- Verify deployment name matches exactly (case-sensitive)
- Check if deployment completed successfully in Azure AI Studio
- Ensure you're using the correct endpoint

### "temperature does not support X with this model"

**Solution:** Set temperature to `1` in your config file:

```bash
# Edit the config
nano ~/.config/k8sgpt/k8sgpt.yaml

# Change or add:
temperature: 1

# Or recreate the config with correct temperature
```

### "Access denied due to invalid subscription key"

1. Verify API key is correct (no extra spaces)
2. Check if key is expired or rotated
3. Try regenerating the key in Azure Portal
4. Ensure you're using the correct endpoint for your resource
5. Verify the deployment name matches exactly

### Connection timeout

- Check network security group allows outbound HTTPS (443)
- Verify endpoint URL is correct (no trailing slashes needed)
- Test from a different network if needed
- Ensure your Azure OpenAI resource is not paused or disabled

### Authentication errors

```bash
# Remove and re-add the provider
k8sgpt auth remove -b azureopenai

# Add again with correct credentials
k8sgpt auth add \
  --backend azureopenai \
  --model gpt-4 \
  --baseurl https://<your-resource>.openai.azure.com/ \
  --engine gpt-4

# Set as default
k8sgpt auth default --provider azureopenai

# Verify
k8sgpt auth list
```

## Security Best Practices

1. **Use Managed Identities** (for production)
   - Configure your VM with a managed identity
   - Grant the identity access to Azure OpenAI
   - No API key needed in code

2. **Rotate API Keys Regularly**
   - Azure Portal → Keys and Endpoint → Regenerate
   - Update K8sGPT config after rotation

3. **Use Private Endpoints** (optional)
   - Restricts access to your VNet only
   - Better security for production

4. **Monitor Access**
   - Azure Monitor logs for API usage
   - Set up alerts for unusual activity

5. **Limit Key Exposure**
   - Don't commit API keys to version control
   - Use environment variables or secure vaults
   - Restrict key permissions in Azure Portal

## Next Steps

After setting up Azure OpenAI:

1. **Test the configuration:**
   ```bash
   k8sgpt analyze --explain
   ```

2. **Deploy sample broken workloads:**
   ```bash
   kubectl apply -f manifests/
   ```

3. **Run analysis:**
   ```bash
   k8sgpt analyze --explain
   k8sgpt analyze --namespace default --explain
   ```

4. **Explore K8sGPT features:**
   ```bash
   k8sgpt list-analyzers
   k8sgpt analyze --analyzers pod,service --explain
   ```

## Additional Resources

- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
- [K8sGPT Documentation](https://docs.k8sgpt.ai/)
- [Azure OpenAI Models](https://learn.microsoft.com/azure/ai-services/openai/concepts/models)
- [Azure AI Studio](https://ai.azure.com/)

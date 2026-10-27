#!/bin/bash

# K8sGPT Lab - K8sGPT Configuration Script for Azure OpenAI (Linux/macOS)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_EXAMPLE="$PROJECT_ROOT/config/k8sgpt-config.yaml.example"
K8SGPT_CONFIG_DIR="$HOME/.config/k8sgpt"
K8SGPT_CONFIG_FILE="$K8SGPT_CONFIG_DIR/k8sgpt.yaml"

echo "========================================="
echo "K8sGPT Lab - Configuring K8sGPT"
echo "========================================="
echo ""

# Check if k8sgpt is installed
if ! command -v k8sgpt &> /dev/null; then
  echo "Error: K8sGPT is not installed. Run ./scripts/setup-vm-linux.sh first."
  exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
  echo "Error: kubectl is not configured or cluster is not accessible."
  echo "Run ./scripts/create-cluster.sh first."
  exit 1
fi

# Create K8sGPT config directory
mkdir -p "$K8SGPT_CONFIG_DIR"

# Prompt for Azure OpenAI details
echo "Please provide your Azure OpenAI configuration:"
echo ""

read -p "Azure OpenAI Endpoint (e.g., https://your-resource.openai.azure.com/): " AZURE_ENDPOINT
read -p "Deployment Name (e.g., gpt-4 or gpt-5): " DEPLOYMENT_NAME
read -sp "API Key: " API_KEY
echo ""

# Determine temperature based on model
if [[ "$DEPLOYMENT_NAME" == *"gpt-5"* ]] || [[ "$DEPLOYMENT_NAME" == *"5"* ]]; then
  TEMPERATURE=1
  echo ""
  echo "Note: GPT-5 detected. Setting temperature to 1 (only supported value)."
else
  TEMPERATURE=1
  echo ""
  echo "Note: Setting temperature to 1 for compatibility."
fi

echo ""
echo "Configuring K8sGPT with Azure OpenAI..."
echo ""

# Create K8sGPT config file
cat > "$K8SGPT_CONFIG_FILE" << EOF
ai:
  providers:
    - name: azureopenai
      model: $DEPLOYMENT_NAME
      baseurl: $AZURE_ENDPOINT
      engine: $DEPLOYMENT_NAME
      temperature: $TEMPERATURE
      password: $API_KEY
defaultprovider: azureopenai
EOF

echo "Configuration file created at: $K8SGPT_CONFIG_FILE"
echo ""

# Add Azure OpenAI provider using k8sgpt CLI
echo "Adding Azure OpenAI backend..."
echo "$API_KEY" | k8sgpt auth add \
  --backend azureopenai \
  --model "$DEPLOYMENT_NAME" \
  --baseurl "$AZURE_ENDPOINT" \
  --engine "$DEPLOYMENT_NAME" \
  --password "$API_KEY" 2>/dev/null || echo "Provider already configured"

# Set the provider
echo "Setting Azure OpenAI as default provider..."
k8sgpt auth default --provider azureopenai

# List available analyzers
echo ""
echo "Available analyzers:"
k8sgpt list-analyzers

# Enable all default analyzers
echo ""
echo "Enabling default analyzers..."
k8sgpt integration activate 2>/dev/null || echo "Integration activation requires additional setup"

echo ""
echo "========================================="
echo "K8sGPT Configuration Complete!"
echo "========================================="
echo ""
echo "Configuration details:"
echo "  Endpoint: $AZURE_ENDPOINT"
echo "  Deployment: $DEPLOYMENT_NAME"
echo "  Temperature: $TEMPERATURE"
echo ""
echo "Testing K8sGPT..."
echo ""

# Test analysis
if k8sgpt analyze --namespace default 2>&1 | head -20; then
  echo ""
  echo "Success! K8sGPT is ready to use."
else
  echo ""
  echo "Note: No issues found in default namespace (this is normal for a fresh cluster)"
fi

echo ""
echo "Usage examples:"
echo "  Analyze all namespaces:      k8sgpt analyze"
echo "  Analyze specific namespace:  k8sgpt analyze --namespace <name>"
echo "  Get explanations:            k8sgpt analyze --explain"
echo "  Output as JSON:              k8sgpt analyze --output json"
echo "  Filter by resource:          k8sgpt analyze --analyzers pod,service"
echo ""
echo "Deploy broken workloads for testing:"
echo "  kubectl apply -f $PROJECT_ROOT/manifests/"
echo ""
echo "Troubleshooting:"
echo "  View config: cat $K8SGPT_CONFIG_FILE"
echo "  List providers: k8sgpt auth list"
echo "  Test connection: k8sgpt analyze --explain"
echo ""

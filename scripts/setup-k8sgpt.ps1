# K8sGPT Lab - K8sGPT Configuration Script for Azure OpenAI (Windows)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$CONFIG_EXAMPLE = Join-Path $PROJECT_ROOT "config\k8sgpt-config.yaml.example"
$K8SGPT_CONFIG_DIR = Join-Path $env:USERPROFILE ".config\k8sgpt"
$K8SGPT_CONFIG_FILE = Join-Path $K8SGPT_CONFIG_DIR "k8sgpt.yaml"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "K8sGPT Lab - Configuring K8sGPT" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if k8sgpt is installed
if (-not (Get-Command k8sgpt -ErrorAction SilentlyContinue)) {
    Write-Host "Error: K8sGPT is not installed. Run .\scripts\setup-vm-windows.ps1 first." -ForegroundColor Red
    exit 1
}

# Check if kubectl is configured
try {
    kubectl cluster-info | Out-Null
} catch {
    Write-Host "Error: kubectl is not configured or cluster is not accessible." -ForegroundColor Red
    Write-Host "Run .\scripts\create-cluster.ps1 first." -ForegroundColor Yellow
    exit 1
}

# Create K8sGPT config directory
if (-not (Test-Path $K8SGPT_CONFIG_DIR)) {
    New-Item -ItemType Directory -Path $K8SGPT_CONFIG_DIR -Force | Out-Null
}

# Prompt for Azure OpenAI details
Write-Host "Please provide your Azure OpenAI configuration:" -ForegroundColor Yellow
Write-Host ""

$AZURE_ENDPOINT = Read-Host "Azure OpenAI Endpoint (e.g., https://your-resource.openai.azure.com/)"
$DEPLOYMENT_NAME = Read-Host "Deployment Name (e.g., gpt-4 or gpt-5)"
$API_KEY = Read-Host "API Key" -AsSecureString
$API_KEY_PLAIN = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($API_KEY))

# Determine temperature based on model
if ($DEPLOYMENT_NAME -like "*gpt-5*" -or $DEPLOYMENT_NAME -like "*5*") {
    $TEMPERATURE = 1
    Write-Host ""
    Write-Host "Note: GPT-5 detected. Setting temperature to 1 (only supported value)." -ForegroundColor Yellow
} else {
    $TEMPERATURE = 1
    Write-Host ""
    Write-Host "Note: Setting temperature to 1 for compatibility." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Configuring K8sGPT with Azure OpenAI..." -ForegroundColor Yellow
Write-Host ""

# Create K8sGPT config file
$CONFIG_CONTENT = @"
ai:
  providers:
    - name: azureopenai
      model: $DEPLOYMENT_NAME
      baseurl: $AZURE_ENDPOINT
      engine: $DEPLOYMENT_NAME
      temperature: $TEMPERATURE
      password: $API_KEY_PLAIN
defaultprovider: azureopenai
"@

Set-Content -Path $K8SGPT_CONFIG_FILE -Value $CONFIG_CONTENT -Force

Write-Host "Configuration file created at: $K8SGPT_CONFIG_FILE" -ForegroundColor Green
Write-Host ""

# Add Azure OpenAI provider using k8sgpt CLI
Write-Host "Adding Azure OpenAI backend..." -ForegroundColor Yellow

# Remove existing provider if exists
k8sgpt auth remove -b azureopenai 2>$null

# Add provider with API key
$API_KEY_PLAIN | k8sgpt auth add `
  --backend azureopenai `
  --model $DEPLOYMENT_NAME `
  --baseurl $AZURE_ENDPOINT `
  --engine $DEPLOYMENT_NAME

# Set the provider
Write-Host "Setting Azure OpenAI as default provider..." -ForegroundColor Yellow
k8sgpt auth default --provider azureopenai

# List available analyzers
Write-Host ""
Write-Host "Available analyzers:" -ForegroundColor White
k8sgpt list-analyzers

# Enable all default analyzers
Write-Host ""
Write-Host "Enabling default analyzers..." -ForegroundColor Yellow
k8sgpt integration activate 2>$null

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "K8sGPT Configuration Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configuration details:" -ForegroundColor White
Write-Host "  Endpoint: $AZURE_ENDPOINT"
Write-Host "  Deployment: $DEPLOYMENT_NAME"
Write-Host "  Temperature: $TEMPERATURE"
Write-Host ""
Write-Host "Testing K8sGPT..." -ForegroundColor Yellow
Write-Host ""

# Test analysis
k8sgpt analyze --namespace default 2>&1 | Select-Object -First 20

Write-Host ""
Write-Host "Usage examples:" -ForegroundColor Yellow
Write-Host "  Analyze all namespaces:      k8sgpt analyze" -ForegroundColor White
Write-Host "  Analyze specific namespace:  k8sgpt analyze --namespace <name>" -ForegroundColor White
Write-Host "  Get explanations:            k8sgpt analyze --explain" -ForegroundColor White
Write-Host "  Output as JSON:              k8sgpt analyze --output json" -ForegroundColor White
Write-Host "  Filter by resource:          k8sgpt analyze --analyzers pod,service" -ForegroundColor White
Write-Host ""
Write-Host "Deploy broken workloads for testing:" -ForegroundColor Yellow
Write-Host "  kubectl apply -f $PROJECT_ROOT\manifests\" -ForegroundColor White
Write-Host ""
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "  View config: cat $K8SGPT_CONFIG_FILE" -ForegroundColor White
Write-Host "  List providers: k8sgpt auth list" -ForegroundColor White
Write-Host "  Test connection: k8sgpt analyze --explain" -ForegroundColor White
Write-Host ""

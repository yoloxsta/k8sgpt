# K8sGPT Lab - Kind Cluster Creation Script (Windows)

$ErrorActionPreference = "Stop"

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$PROJECT_ROOT = Split-Path -Parent $SCRIPT_DIR
$CONFIG_FILE = Join-Path $PROJECT_ROOT "config\kind-cluster.yaml"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "K8sGPT Lab - Creating Kind Cluster" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if kind is installed
if (-not (Get-Command kind -ErrorAction SilentlyContinue)) {
    Write-Host "Error: kind is not installed. Run .\scripts\setup-vm-windows.ps1 first." -ForegroundColor Red
    exit 1
}

# Check if kubectl is installed
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "Error: kubectl is not installed. Run .\scripts\setup-vm-windows.ps1 first." -ForegroundColor Red
    exit 1
}

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "Error: Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Check if config file exists
if (-not (Test-Path $CONFIG_FILE)) {
    Write-Host "Error: Kind config file not found at $CONFIG_FILE" -ForegroundColor Red
    exit 1
}

# Check if cluster already exists
$existingClusters = kind get clusters 2>&1
if ($existingClusters -contains "k8sgpt-lab") {
    Write-Host "Cluster 'k8sgpt-lab' already exists." -ForegroundColor Yellow
    $response = Read-Host "Do you want to delete and recreate it? (Y/N)"
    if ($response -eq 'Y' -or $response -eq 'y') {
        Write-Host "Deleting existing cluster..." -ForegroundColor Yellow
        kind delete cluster --name k8sgpt-lab
    } else {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "Creating kind cluster..." -ForegroundColor Yellow
Write-Host ""

# Create cluster
kind create cluster --config $CONFIG_FILE

Write-Host ""
Write-Host "Cluster created successfully!" -ForegroundColor Green
Write-Host ""

# Set kubeconfig
Write-Host "Setting kubeconfig..." -ForegroundColor Yellow
kubectl cluster-info --context kind-k8sgpt-lab

# Install Metrics Server (required for some K8sGPT analyzers)
Write-Host ""
Write-Host "Installing Metrics Server..." -ForegroundColor Yellow
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/metrics-server/main/manifests/base/deployment.yaml

# Patch metrics server for kind (allows self-signed certs)
kubectl patch deployment metrics-server -n kube-system --type='json' `
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Wait for metrics server to be ready
Write-Host "Waiting for Metrics Server to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system

# Install NGINX Ingress Controller (optional, for ingress testing)
Write-Host ""
Write-Host "Installing NGINX Ingress Controller..." -ForegroundColor Yellow
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
Write-Host "Waiting for Ingress Controller to be ready..." -ForegroundColor Yellow
kubectl wait --namespace ingress-nginx `
  --for=condition=ready pod `
  --selector=app.kubernetes.io/component=controller `
  --timeout=300s

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Kind Cluster Setup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cluster information:" -ForegroundColor White
kubectl get nodes
Write-Host ""
Write-Host "System pods:" -ForegroundColor White
kubectl get pods -n kube-system
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Configure K8sGPT: Edit $PROJECT_ROOT\config\k8sgpt-config.yaml" -ForegroundColor White
Write-Host "2. Initialize K8sGPT: .\scripts\setup-k8sgpt.ps1" -ForegroundColor White
Write-Host "3. Deploy test workloads: kubectl apply -f $PROJECT_ROOT\manifests\" -ForegroundColor White
Write-Host ""

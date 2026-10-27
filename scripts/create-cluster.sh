#!/bin/bash

# K8sGPT Lab - Kind Cluster Creation Script (Linux/macOS)

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config/kind-cluster.yaml"

echo "========================================="
echo "K8sGPT Lab - Creating Kind Cluster"
echo "========================================="
echo ""

# Check if kind is installed
if ! command -v kind &> /dev/null; then
  echo "Error: kind is not installed. Run ./scripts/setup-vm-linux.sh first."
  exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
  echo "Error: kubectl is not installed. Run ./scripts/setup-vm-linux.sh first."
  exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
  echo "Error: Docker is not running. Please start Docker first."
  exit 1
fi

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Kind config file not found at $CONFIG_FILE"
  exit 1
fi

# Check if cluster already exists
if kind get clusters | grep -q "k8sgpt-lab"; then
  echo "Cluster 'k8sgpt-lab' already exists."
  read -p "Do you want to delete and recreate it? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deleting existing cluster..."
    kind delete cluster --name k8sgpt-lab
  else
    echo "Aborted."
    exit 0
  fi
fi

echo "Creating kind cluster..."
echo ""

# Create cluster
kind create cluster --config "$CONFIG_FILE"

echo ""
echo "Cluster created successfully!"
echo ""

# Set kubeconfig
echo "Setting kubeconfig..."
kubectl cluster-info --context kind-k8sgpt-lab

# Install Metrics Server (required for some K8sGPT analyzers)
echo ""
echo "Installing Metrics Server..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/metrics-server/main/manifests/base/deployment.yaml

# Patch metrics server for kind (allows self-signed certs)
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Wait for metrics server to be ready
echo "Waiting for Metrics Server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system

# Install NGINX Ingress Controller (optional, for ingress testing)
echo ""
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
echo "Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo ""
echo "========================================="
echo "Kind Cluster Setup Complete!"
echo "========================================="
echo ""
echo "Cluster information:"
kubectl get nodes
echo ""
echo "System pods:"
kubectl get pods -n kube-system
echo ""
echo "Next steps:"
echo "1. Configure K8sGPT: Edit $PROJECT_ROOT/config/k8sgpt-config.yaml"
echo "2. Initialize K8sGPT: ./scripts/setup-k8sgpt.sh"
echo "3. Deploy test workloads: kubectl apply -f $PROJECT_ROOT/manifests/"
echo ""

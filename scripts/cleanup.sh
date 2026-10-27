#!/bin/bash

# K8sGPT Lab - Environment Cleanup Script (Linux/macOS)

set -e

echo "========================================="
echo "K8sGPT Lab - Cleanup Script"
echo "========================================="
echo ""

# Ask for confirmation
read -p "This will delete the kind cluster and clean up resources. Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Delete kind cluster
echo ""
echo "Deleting kind cluster..."
if kind get clusters | grep -q "k8sgpt-lab"; then
  kind delete cluster --name k8sgpt-lab
  echo "Cluster deleted."
else
  echo "No k8sgpt-lab cluster found."
fi

# Remove K8sGPT auth
echo ""
echo "Removing K8sGPT configuration..."
if command -v k8sgpt &> /dev/null; then
  k8sgpt auth remove --backend azureopenai || true
  echo "K8sGPT auth removed."
fi

# Clean up any orphaned Docker resources
echo ""
echo "Cleaning up Docker resources..."
docker system prune -f

echo ""
echo "========================================="
echo "Cleanup Complete!"
echo "========================================="
echo ""
echo "To recreate the environment, run:"
echo "  ./scripts/create-cluster.sh"
echo "  ./scripts/setup-k8sgpt.sh"
echo ""

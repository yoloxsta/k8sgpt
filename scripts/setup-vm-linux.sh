#!/bin/bash

# K8sGPT Lab - Azure VM Setup Script for Linux (Ubuntu)
# This script installs Docker, kind, kubectl, and K8sGPT on an Ubuntu VM

set -e

echo "========================================="
echo "K8sGPT Lab - Azure VM Setup (Linux)"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

# Update system packages
echo "[1/6] Updating system packages..."
apt-get update && apt-get upgrade -y

# Install required packages
echo "[2/6] Installing required packages..."
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  wget \
  git

# Install Docker
echo "[3/6] Installing Docker..."
if ! command -v docker &> /dev/null; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  
  # Enable and start Docker
  systemctl enable docker
  systemctl start docker
  
  # Add current user to docker group (if not root)
  if [ "$SUDO_USER" ]; then
    usermod -aG docker $SUDO_USER
    echo "Added $SUDO_USER to docker group. You may need to log out and back in."
  fi
else
  echo "Docker already installed, skipping..."
fi

# Install kubectl
echo "[4/6] Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  mv kubectl /usr/local/bin/
  
  # Enable bash completion
  kubectl completion bash | tee /etc/bash_completion.d/kubectl > /dev/null
else
  echo "kubectl already installed, skipping..."
fi

# Install kind
echo "[5/6] Installing kind..."
if ! command -v kind &> /dev/null; then
  curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
  chmod +x ./kind
  mv ./kind /usr/local/bin/kind
else
  echo "kind already installed, skipping..."
fi

# Install K8sGPT
echo "[6/6] Installing K8sGPT..."
if ! command -v k8sgpt &> /dev/null; then
  # Download K8sGPT DEB package (more reliable than tarball)
  curl -LO https://github.com/k8sgpt-ai/k8sgpt/releases/download/v0.3.48/k8sgpt_amd64.deb
  dpkg -i k8sgpt_amd64.deb
  rm k8sgpt_amd64.deb
  
  # Enable bash completion
  k8sgpt completion bash | tee /etc/bash_completion.d/k8sgpt > /dev/null
else
  echo "K8sGPT already installed, skipping..."
fi

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Installed versions:"
echo "  Docker:   $(docker --version)"
echo "  kubectl:  $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
echo "  kind:     $(kind version)"
echo "  k8sgpt:   $(k8sgpt version)"
echo ""
echo "IMPORTANT: Docker group changes require session restart"
echo "Run: newgrp docker"
echo ""
echo "Next steps:"
echo "1. Run: newgrp docker"
echo "2. Create kind cluster: ./scripts/create-cluster.sh"
echo "3. Configure K8sGPT with your preferred AI backend:"
echo "   - Azure OpenAI: Edit config/k8sgpt-config.yaml"
echo "   - Ollama (local): curl -fsSL https://ollama.com/install.sh | sh"
echo "4. Initialize K8sGPT: ./scripts/setup-k8sgpt.sh"
echo ""

#!/usr/bin/env bash
# install_docker_k8s.sh: Installs latest Docker and Kubernetes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/" && pwd)"
source "$SCRIPT_DIR/functions/log-utils.sh"

# Set trap for error handling
trap 'handle_error $LINENO' ERR

# Function to check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}

# Function to install dependencies
install_dependencies() {
  log "INFO" "Installing dependencies"
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
}

# Function to install Docker
install_docker() {
  if command_exists docker; then
    log "INFO" "Docker is already installed"
    return
  fi
  log "INFO" "=== Installing latest Docker ==="
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh
  rm get-docker.sh
  log "INFO" "Docker installation complete"
}

# Function to install Kubernetes
install_kubernetes() {
  if command_exists kubeadm; then
    log "INFO" "Kubernetes is already installed"
    return
  fi

  log "INFO" "=== Installing Kubernetes (kubeadm, kubelet, kubectl) ==="

    # 1. Dynamically fetch latest stable tag
    K8S_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"  # :contentReference[oaicite:8]{index=8}

    # 2. Prepare keyrings and avoid prompts
    sudo mkdir -p /etc/apt/keyrings
    sudo rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    # 3. Download & install GPG key non-interactively
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" \
    | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg  # :contentReference[oaicite:9]{index=9}

    # 4. Add the versioned APT source
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
    https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list

    # 5. Install & pin packages
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl

  log "INFO" "Kubernetes installation complete"
}



# Main execution
install_dependencies
install_docker
install_kubernetes

log "INFO" "=== Enabling Docker & Kubelet ==="
sudo systemctl enable --now docker
sudo systemctl enable --now kubelet

log "INFO" "=== Docker and Kubernetes installation complete ==="
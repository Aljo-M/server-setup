#!/usr/bin/env bash
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load logging utilities
source "$SCRIPT_DIR/functions/log-utils.sh"

# Load configuration
source "$SCRIPT_DIR/config/variable-loader.sh" "$@"

# Disable swap for Kubernetes
disable_swap() {
    log "INFO" "Disabling swap for Kubernetes compatibility"
    swapoff -a || true
    
    # Comment out swap entries in fstab
    if [ -f /etc/fstab ]; then
        cp /etc/fstab /etc/fstab.bak.$(date +%F-%H%M%S)
        sed -i '/swap/s/^/#/' /etc/fstab
        log "INFO" "Swap disabled in /etc/fstab"
    fi
}

install_dependencies() {
    log "INFO" "Installing dependencies"
    
    # Update package index
    apt-get update -qq
    
    # Install prerequisites
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common \
        || { log "ERROR" "Failed to install prerequisites"; return 1; }
        
    log "INFO" "Dependencies installed successfully"
    return 0
}

install_docker() {
    log "INFO" "=== Installing latest Docker ==="
    
    # Check if Docker is already installed
    if command -v docker &>/dev/null && docker --version &>/dev/null; then
        log "INFO" "Docker is already installed"
        docker --version | head -n 1
        return 0
    fi
    
    # Install Docker using official install script
    mkdir -p /etc/apt/keyrings
    
    # Remove old Docker GPG key if it exists
    rm -f /etc/apt/keyrings/docker.asc 2>/dev/null || true
    
    # Download Docker GPG key
    curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    
    # Install Docker
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
    
    # Configure Docker daemon with recommended settings
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "${DOCKER_STORAGE_DRIVER:-overlay2}",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "live-restore": ${DOCKER_LIVE_RESTORE:-true}
}
EOF
    
    # Enable and start Docker
    systemctl enable docker
    systemctl daemon-reload
    systemctl restart docker
    
    # Wait for Docker to be ready
    local max_attempts=30
    local attempt=1
    log "INFO" "Waiting for Docker service to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if docker info &>/dev/null; then
            log "INFO" "Docker is ready"
            break
        fi
        
        log "INFO" "Waiting for Docker... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log "ERROR" "Docker failed to start properly after installation"
        return 1
    fi
    
    # Show Docker version
    log "INFO" "Docker installation complete"
    docker --version | head -n 1
    
    return 0
}

install_kubernetes() {
    log "INFO" "=== Installing Kubernetes v${K8S_VERSION} (kubeadm, kubelet, kubectl) ==="
    
    # Check if Kubernetes components are already installed
    if command -v kubectl &>/dev/null && kubectl version --client &>/dev/null; then
        log "INFO" "Kubernetes components are already installed"
        kubectl version --client --output=yaml | grep -A 1 "clientVersion:" || true
        return 0
    fi
    
    # Add Kubernetes apt repository
    mkdir -p /etc/apt/keyrings
    
    # Remove old keys if they exist
    rm -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null || true
    
    # Download the public signing key
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    
    # Add the Kubernetes apt repository
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
    
    # Update apt package index
    apt-get update
    
    # Install kubelet, kubeadm and kubectl
    apt-get install -y kubelet kubeadm kubectl
    
    # Hold packages at current version to prevent automatic upgrades
    apt-mark hold kubelet kubeadm kubectl
    
    # Configure kubelet to use systemd cgroup driver
    mkdir -p /etc/systemd/system/kubelet.service.d/
    cat > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf <<EOF
[Service]
Environment="KUBELET_
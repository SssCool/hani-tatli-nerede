#!/bin/bash

# Kubernetes v1.33.1 Setup Script (Single Node Control Plane)
# Author: Abdussamed KOÇAK
# Date: 2025-06-18

set -euo pipefail

# ===============================
# Function to print section headers
# ===============================
header() {
    echo
    echo "============================================================"
    echo "$1"
    echo "============================================================"
}

# ===============================
# 1. Update & Upgrade System
# ===============================
header "Updating system packages"
sudo apt update && sudo apt upgrade -y

# ===============================
# 2. Disable Swap
# ===============================
header "Disabling swap (required for Kubernetes)"
if swapon --show | grep -q 'swap'; then
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
else
    echo "Swap already disabled"
fi

# ===============================
# 3. Kernel Modules & sysctl Settings
# ===============================
header "Configuring kernel modules and sysctl for Kubernetes"
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# ===============================
# 4. Install Container Runtime: containerd
# ===============================
header "Installing containerd (container runtime)"
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "bullseye")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

#Install
sudo apt update

if ! command -v containerd &>/dev/null; then
    sudo apt update
    sudo apt install -y containerd.io
else
    echo "containerd already installed"
fi

# Generate clean config and enable SystemdCgroup + CRI
header "Configuring containerd"
sudo mv /etc/containerd/config.toml /etc/containerd/config.toml.bak || true
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

# ===============================
# 5. Add Kubernetes APT Repository
# ===============================
header "Adding Kubernetes APT repository"
sudo mkdir -p /etc/apt/keyrings

if [ ! -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]; then
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
fi

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# ===============================
# 6. Configure Firewall (UFW)
# ===============================
header "Configuring firewall rules (UFW)"
if ! command -v ufw &>/dev/null; then
    sudo apt install -y ufw
fi

sudo ufw allow OpenSSH
sudo ufw allow 6443/tcp       # Kubernetes API Server
sudo ufw allow 2379:2380/tcp  # etcd (optional for external use)
sudo ufw allow 10250/tcp      # kubelet API
sudo ufw allow 30000:32767/tcp # NodePort Services

# Uncomment if running multi-control-plane:
# sudo ufw allow 10251/tcp   # kube-scheduler
# sudo ufw allow 10252/tcp   # kube-controller-manager

sudo ufw --force enable
sudo ufw status verbose

# ===============================
# 7. Initialize Kubernetes Control Plane
# ===============================
header "Initializing Kubernetes cluster with kubeadm"

sudo kubeadm init

# ===============================
# 8. Setup kubectl for Local User
# ===============================
header "Setting up kubectl for current user"

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# ===============================
# 9. Install Pod Network (Calico)
# ===============================
header "Applying Calico CNI (network plugin)"
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# ===============================
# Final Message
# ===============================
header "Kubernetes control plane is ready!"
echo "✅ To join worker nodes, use the kubeadm join command from the init output."
echo "✅ You can now use kubectl to manage your cluster."
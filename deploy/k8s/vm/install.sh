#!/bin/bash

# Update and install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt-get install -y gnupg curl apt-transport-https ca-certificates conntrack

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker ${USER}
sudo sysctl net.bridge.bridge-nf-call-iptables=1

# Install K3s
echo "Installing K3s..."
curl -sfL https://get.k3s.io | sh -
sudo k3s kubectl get nodes
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/${USER}/.kube/kubeconfig.yaml
sudo chown $(id -u):$(id -g) ~/.kube/kubeconfig.yaml
echo 'export KUBECONFIG=$HOME/.kube/kubeconfig.yaml' >> ~/.bashrc
kubectl get nodes

# Install Helm
echo "Installing Helm..."
curl https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor -o /usr/share/keyrings/helm.gpg
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | \
sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update
sudo apt install helm -y
helm version
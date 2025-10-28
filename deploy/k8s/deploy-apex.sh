#!/bin/bash

set -e

cd acuvity

# Use prod values file
cp apex-agent/apex-agent-values-template.yaml apex-agent/apex-agent-values.yaml

IMAGE_TAG="stable"
HELM_TAG="1.0.0"

while getopts "aijt:" opt; do
  case $opt in
    a)
      echo "Using acumux setup..."
      [ -f "$HOME/ca-chain-external.pem" ] || { echo "missing CA. copy ca-chain-external.pem to $HOME/ca-chain-external.pem."; exit 1; }
      MODE="acumux"
      cp apex-agent/apex-agent-acumux-values.yaml apex-agent/apex-agent-values.yaml
      ;;
    i)
      IMAGE_TAG="$OPTARG"
      ;;
    j)
      HELM_TAG="$OPTARG"
      ;;
    t)
      TOKEN=$OPTARG
      cp apex-agent/acuvity-apptoken-template.yaml apex-agent/acuvity-apptoken.yaml
      sed -i "s/YOUR_APP_TOKEN_HERE/$TOKEN/" apex-agent/acuvity-apptoken.yaml
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# replace the image tag
sed -i "s/tag: \".*\"/tag: \"$IMAGE_TAG\"/" apex-agent/apex-agent-values.yaml

kubectl -n mcp-demo get pods || { echo "no mcp-demo namespace found"; exit 1; }

[ -f apex-agent/acuvity-apptoken.yaml ] || { echo "missing token file."; exit 1; }

echo "----------------------------------------------------"
echo "Removing cert-manager and acuvity namespaces..."
echo "----------------------------------------------------"

kubectl delete namespace cert-manager  || { echo "no cert-manager namespace found"; }
kubectl delete namespace acuvity       || { echo "no acuvity namespace found"; }

echo "----------------------------------------------------"
echo "Creating acuvity namespace..."
echo "----------------------------------------------------"
kubectl apply -f apex-agent/acuvity-namespace.yaml

echo "----------------------------------------------------"
echo "Installing cert manager..."
echo "----------------------------------------------------"

helm repo add jetstack https://charts.jetstack.io --force-update
helm install cert-manager jetstack/cert-manager   --namespace cert-manager   --create-namespace   --version v1.15.1   --set crds.enabled=true

echo "----------------------------------------------------"
echo "Creating trust-manager for acuvity namespace..."
echo "----------------------------------------------------"
helm upgrade trust-manager jetstack/trust-manager   --install   --namespace cert-manager   --set app.trust.namespace=acuvity   --wait

kubectl apply -f apex-agent/cert-manager-resources.yaml

if [ "$MODE" == "acumux" ]; then
    echo "----------------------------------------------------"
    echo "Trust External Certs if needed..."
    echo "----------------------------------------------------"
	kubectl -n acuvity create configmap ca-cert-config --from-file="$HOME/ca-chain-external.pem"

	echo "----------------------------------------------------"
    echo "Add reachability in k8s to API gateway for Apex..."
    echo "----------------------------------------------------"
	kubectl -n acuvity apply -f apex-agent/apex-agent-acumux-svc.yaml
fi

echo "----------------------------------------------------"
echo "Creating app token secret..."
echo "----------------------------------------------------"
kubectl apply -f apex-agent/acuvity-apptoken.yaml

echo "----------------------------------------------------"
echo "Install Apex..."
echo "----------------------------------------------------"
helm upgrade apex oci://docker.io/acuvity/apex-agent --version "$HELM_TAG" --install --create-namespace --namespace acuvity -f apex-agent/apex-agent-values.yaml

#!/bin/bash

[ -f apex-agent/acuvity-apptoken.yaml ] || { echo "missing token file."; exit 1; }

echo "----------------------------------------------------"
echo "Installing Apex..."
echo "----------------------------------------------------"

echo "Creating acuvity namespace..."
kubectl apply -f apex-agent/acuvity-namespace.yaml
kubectl get namespaces --show-labels
kubectl -n acuvity get cm
kubectl apply -f apex-agent/cert-manager-resources.yaml

echo "Creating app token secret..."

# NOTE: You need to create the acuvity-apptoken.yaml file with the actual token.
# cp apex-agent/acuvity-apptoken-template.yaml apex-agent/acuvity-apptoken.yaml
# Replace the placeholder with the actual token
kubectl apply -f apex-agent/acuvity-apptoken.yaml

echo "Install Apex..."
helm upgrade apex  charts/apex-agent-v0.0.0-e85d2014.tgz --install --create-namespace --namespace acuvity -f apex-agent/apex-agent-values.yaml

echo "Redeploy Agent..."

kubectl label namespace mcp-demo acuvity.ai/inject-custom-ca=enabled
helm -n mcp-demo upgrade mcp-demo ../charts/mcp-demo --set apex.enabled=true --reuse-values
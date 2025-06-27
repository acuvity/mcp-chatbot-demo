#!/bin/bash

set -e

cd acuvity

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

if [ -f $HOME/ca-chain-external.pem ]; then
        echo "----------------------------------------------------"
        echo "Trust External Certs if needed..."
        echo "----------------------------------------------------"
	kubectl -n acuvity create configmap ca-cert-config --from-file=$HOME/ca-chain-external.pem

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
helm upgrade apex  charts/apex-agent-v0.0.0-e85d2014.tgz --install --create-namespace --namespace acuvity -f apex-agent/apex-agent-values.yaml

echo "----------------------------------------------------"
echo "Redeploy Agent..."
echo "----------------------------------------------------"
kubectl label namespace mcp-demo acuvity.ai/inject-custom-ca=enabled
helm -n mcp-demo upgrade mcp-demo ../charts/mcp-demo --set apex.enabled=true --reuse-values
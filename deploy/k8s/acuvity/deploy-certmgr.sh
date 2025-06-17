#!/bin/bash

echo "----------------------------------------------------"
echo "Installing cert/trust manager..."
echo "----------------------------------------------------"

helm repo add jetstack https://charts.jetstack.io --force-update
helm install cert-manager jetstack/cert-manager   --namespace cert-manager   --create-namespace   --version v1.15.1   --set crds.enabled=true
helm upgrade trust-manager jetstack/trust-manager   --install   --namespace cert-manager   --set app.trust.namespace=acuvity   --wait
kubectl get namespaces --show-labels
kubectl -n cert-manager get pods


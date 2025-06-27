#!/bin/bash


echo "----------------------------------------------------"
echo "Checking K3s nodes..."
echo "----------------------------------------------------"
echo "----> nodes"
kubectl get nodes


echo "----------------------------------------------------"
echo "Checking Kubernetes namespaces..."
echo "----------------------------------------------------"
echo "----> namespaces"
kubectl get namespaces --show-labels

echo "----------------------------------------------------"
echo "Checking Cert Manager..."
echo "----------------------------------------------------"
echo "----> pods"
kubectl -n cert-manager get pods

echo "----------------------------------------------------"
echo "Checking Apex..."
echo "----------------------------------------------------"
echo "----> services"
kubectl -n acuvity get services
echo "----> pods"
kubectl -n acuvity get pods
echo "----> config_map"
kubectl -n acuvity get cm
echo "----> secrets"
kubectl -n acuvity get secrets

echo "----------------------------------------------------"
echo "Checking MCP Demo..."
echo "----------------------------------------------------"
echo "----> pods"
kubectl -n mcp-demo get pods
echo "----> config_map"
kubectl -n mcp-demo get cm
echo "----> secrets"
kubectl -n mcp-demo get secrets
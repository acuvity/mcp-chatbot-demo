#!/bin/bash


echo "----------------------------------------------------"
echo "Checking K3s nodes..."
echo "----------------------------------------------------"
kubectl get nodes


echo "----------------------------------------------------"
echo "Checking Kubernetes namespaces..."
echo "----------------------------------------------------"
kubectl get namespaces --show-labels


echo "----------------------------------------------------"
echo "Checking Apex..."
echo "----------------------------------------------------"
kubectl -n acuvity get pods
kubectl -n acuvity get cm
kubectl -n acuvity get secrets


echo "----------------------------------------------------"
echo "Checking MCP Demo..."
echo "----------------------------------------------------"
kubectl -n mcp-demo get pods
kubectl -n mcp-demo get cm
kubectl -n mcp-demo get secrets



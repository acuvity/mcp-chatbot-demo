#!/bin/bash

set -e

cd acuvity

# Use prod values file
cp apex-agent/apex-agent-values-template.yaml apex-agent/apex-agent-values.yaml

IMAGE_TAG="stable"
HELM_TAG="1.0.0"

while getopts "ai:j:t:" opt; do
  case $opt in
    a)
      echo "Using acumux setup..."
      if [ -z "$ACUVITY_REPO" ] ; then
        echo "ACUVITY_REPO is not set. Please set it to your Acuvity repository path on your disk."
        exit 1
      fi

      # check that the CA certificate is where we would expect it to be
      [ -f "$ACUVITY_REPO/backend/dev/data/certificates/ca-chain-external.pem" ] || { echo "Missing CA at: $ACUVITY_REPO/backend/dev/data/certificates/ca-chain-external.pem! Are you sure you are running acumux?"; exit 1; }

      # check that the acumux token is where we would expect it to be
      [ -f "$ACUVITY_REPO/backend/dev/data/apex-agent-apptoken" ] || { echo "Missing acumux app agent token at: $ACUVITY_REPO/backend/dev/data/apex-agent-apptoken! Are you sure you are running acumux?"; exit 1; }

      MODE="acumux"
      cp apex-agent/apex-agent-acumux-values.yaml apex-agent/apex-agent-values.yaml

      # TODO: we should actually use the helm chart and the image from the repo, but that will require some more work, and is not what most people will want anyways
      # switch to the latest development image and helm chart
      IMAGE_TAG="unstable"
      HELM_TAG="1.0.0-unstable"

      # use the acumux generated token
      TOKEN=$(cat "$ACUVITY_REPO/backend/dev/data/apex-agent-apptoken")
      cp apex-agent/acuvity-apptoken-template.yaml apex-agent/acuvity-apptoken.yaml
      sed -i.bak "s|YOUR_APP_TOKEN_HERE|$TOKEN|" apex-agent/acuvity-apptoken.yaml && rm -f apex-agent/acuvity-apptoken.yaml.bak
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
      sed -i.bak "s|YOUR_APP_TOKEN_HERE|$TOKEN|" apex-agent/acuvity-apptoken.yaml && rm -f apex-agent/acuvity-apptoken.yaml.bak
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# replace the image tag
sed -i.bak "s|tag: \".*\"|tag: \"$IMAGE_TAG\"|" apex-agent/apex-agent-values.yaml && rm -f apex-agent/apex-agent-values.yaml.bak

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
	kubectl -n acuvity create configmap ca-cert-config --from-file="$ACUVITY_REPO/backend/dev/data/certificates/ca-chain-external.pem"

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

#!/bin/bash

set -e

[ "$BRAVE_API_KEY" ] || { echo "BRAVE_API_KEY is not set. Please export it before running this script."; exit 1; }
[ "$ANTHROPIC_API_KEY" ] || { echo "ANTHROPIC_API_KEY is not set. Please export it before running this script."; exit 1; }

echo "Create or ensure the namespace 'mcp-demo' exists..."
kubectl create namespace mcp-demo || echo "Namespace 'mcp-demo' already exists."

echo "Installing MCP Server Fetch..."
helm -n mcp-demo install mcp-server-fetch oci://docker.io/acuvity/mcp-server-fetch --version 1.0.0

echo "Installing Brave MCP Server..."
kubectl -n mcp-demo create secret generic brave-api-key --from-literal=BRAVE_API_KEY=${BRAVE_API_KEY}
helm -n mcp-demo install mcp-server-brave-search oci://docker.io/acuvity/mcp-server-brave-search --version 1.0.0 \
        --set secrets.BRAVE_API_KEY.valueFrom.name=brave-api-key \
        --set secrets.BRAVE_API_KEY.valueFrom.key=BRAVE_API_KEY

echo "Installing Memory MCP Server..."
helm -n mcp-demo install mcp-server-memory oci://docker.io/acuvity/mcp-server-memory --version 1.0.0

echo "Installing Sequential Thinking MCP Server..."
helm -n mcp-demo install mcp-server-sequential-thinking oci://docker.io/acuvity/mcp-server-sequential-thinking --version 1.0.0

echo "Creating values.yaml for MCP Servers to be used by chatbot..."
echo "mcpServers:
  - name: mcp-server-fetch
    host:
  - name: mcp-server-brave-search
    host:
  - name: mcp-server-memory
    host:
  - name: mcp-server-sequential-thinking
    host:
" > values.yaml

helm -n mcp-demo install mcp-demo charts/mcp-demo -f values.yaml --set secrets.anthropic_key=$ANTHROPIC_API_KEY

echo "MCP Servers deployed successfully."
#!/bin/bash

set -e

[ "$ANTHROPIC_API_KEY" ] || { echo "ANTHROPIC_API_KEY is not set. Please export it before running this script."; exit 1; }

echo "Create or ensure the namespace 'mcp-demo' exists..."
kubectl create namespace mcp-demo || echo "Namespace 'mcp-demo' already exists."

echo "Installing MCP Server Fetch..."
helm -n mcp-demo install mcp-server-fetch oci://docker.io/acuvity/mcp-server-fetch --version 1.0.0

echo "Installing Memory MCP Server..."
helm -n mcp-demo install mcp-server-memory oci://docker.io/acuvity/mcp-server-memory --version 1.0.0

echo "Installing Sequential Thinking MCP Server..."
helm -n mcp-demo install mcp-server-sequential-thinking oci://docker.io/acuvity/mcp-server-sequential-thinking --version 1.0.0

echo "Creating values.yaml for MCP Servers to be used by chatbot..."
echo "mcpServers:
  - name: mcp-server-fetch
    host:
  - name: mcp-server-memory
    host:
  - name: mcp-server-sequential-thinking
    host:
" > values.yaml

helm -n mcp-demo install mcp-demo charts/mcp-demo -f values.yaml --set secrets.anthropic_key=$ANTHROPIC_API_KEY

echo "MCP Servers deployed successfully."
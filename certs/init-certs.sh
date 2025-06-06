#!/bin/bash

set -e

echo "Generating root CA certificate and key..."
[ -f ./ca-root-cert.pem ] || tg cert --name "ca-root" --is-ca --common-name "MCP Agents System Root CA" --out ./

echo "Generating Agent certificates..."
[ -f ./mcp-chatbot-ui-cert.pem ] || tg cert --name "mcp-chatbot-ui" --common-name "mcp-chatbot-ui.acuvity.ai" --auth-server --dns localhost --ip 127.0.0.1 --dns mcp-chatbot-ui.acuvity.ai --signing-cert .//ca-root-cert.pem --signing-cert-key .//ca-root-key.pem --out ./
[ -f ./mcp-chatbot-agent-cert.pem ] || tg cert --name "mcp-chatbot-agent" --common-name "mcp-chatbot-agent.acuvity.ai" --auth-server --dns localhost --ip 127.0.0.1 --dns mcp-chatbot-agent.acuvity.ai --signing-cert .//ca-root-cert.pem --signing-cert-key .//ca-root-key.pem --out ./

echo "Generating MCP Server certificates..."
[ -f ./mcp-server-fetch-cert.pem ] || tg cert --name "mcp-server-fetch" --common-name "mcp-server-fetch" --auth-server --dns localhost --ip 127.0.0.1 --dns mcp-server-fetch --signing-cert .//ca-root-cert.pem --signing-cert-key .//ca-root-key.pem --out ./
[ -f ./mcp-server-brave-search-cert.pem ] || tg cert --name "mcp-server-brave-search" --common-name "mcp-server-brave-search" --auth-server --dns localhost --ip 127.0.0.1 --dns mcp-server-brave-search --signing-cert .//ca-root-cert.pem --signing-cert-key .//ca-root-key.pem --out ./
[ -f ./mcp-server-github-cert.pem ] || tg cert --name "mcp-server-github" --common-name "mcp-server-github" --auth-server --dns localhost --ip 127.0.0.1 --dns mcp-server-github --signing-cert .//ca-root-cert.pem --signing-cert-key .//ca-root-key.pem --out ./
[ -f ./mcp-server-sequential-thinking-cert.pem ] || tg cert --name "mcp-server-sequential-thinking" --common-name "mcp-server-sequential-thinking" --auth-server --dns localhost --ip 127.0.0.1 --dns mcp-server-sequential-thinking --signing-cert .//ca-root-cert.pem --signing-cert-key .//ca-root-key.pem --out ./
[ -f ./mcp-server-memory-cert.pem ] || tg cert --name "mcp-server-memory" --common-name "mcp-server-memory" --auth-server --dns localhost --ip 127.0.0.1 --dns mcp-server-memory --signing-cert .//ca-root-cert.pem --signing-cert-key .//ca-root-key.pem --out ./
[ -f ./mcp-server-microsoft-cert.pem ] || tg cert --name "mcp-server-microsoft" --common-name "mcp-server-microsoft" --auth-server --dns localhost --ip 127.0.0.1 --dns mcp-server-microsoft --signing-cert .//ca-root-cert.pem --signing-cert-key .//ca-root-key.pem --out ./


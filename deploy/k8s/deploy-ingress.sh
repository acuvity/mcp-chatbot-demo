#!/bin/bash

set -e

[ "$ANTHROPIC_API_KEY" ] || { echo "ANTHROPIC_API_KEY is not set. Please export it before running this script."; exit 1; }

APP_NS="mcp-demo"
INGRESS_NS="ingress-nginx"

# ---- Pre-check: ensure base deployment exists ----
if ! kubectl get namespace "$APP_NS" >/dev/null 2>&1; then
  echo "ERROR: Namespace '$APP_NS' does not exist."
  echo "Please run 'deploy-mcp-demo.sh' first."
  exit 1
fi

echo "Namespace '$APP_NS' exists. Proceeding with update..."


# ---- Install ingress-nginx controller ----
echo "Installing ingress-nginx controller..."
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace \
  --set controller.ingressClassResource.name=nginx \
  --set controller.ingressClass=nginx \
  --set controller.service.type=LoadBalancer

echo "Waiting for ingress-nginx controller to be ready..."
kubectl -n "$INGRESS_NS" rollout status deployment/ingress-nginx-controller --timeout=300s

# ---- Apply Ingress for UI + Agent ----
echo "Applying Ingress for MCP Demo..."
cat | kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mcp-demo
  namespace: ${APP_NS}
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: mcp-demo-agent
            port:
              number: 8000
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mcp-demo-ui
            port:
              number: 3000
EOF

# ---- Upgrade MCP Demo ----
echo "Upgrading MCP Chatbot Demo..."
helm -n "$APP_NS" upgrade --install mcp-demo charts/mcp-demo \
  -f values.yaml \
  --set ui.apiBaseURL="/api/v1/chat" \
  --set agent.corsOrigins='["*"]' \
  --set secrets.anthropic_key="$ANTHROPIC_API_KEY"

# ---- Print external IP / hostname ----
echo "Fetching ingress external IP/hostname..."
EXT_ADDR=$(kubectl -n "$INGRESS_NS" get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$EXT_ADDR" ]; then
  EXT_ADDR=$(kubectl -n "$INGRESS_NS" get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
fi

echo ""
echo "______________________________________________________________________"
echo "MCP Demo updated successfully with ingress, no port-forward necessary."
echo "If apex agent is enabled: Add this to allowed hosts in your ingress policy for mcp-demo-agent:"
echo "  ${EXT_ADDR:-<not-ready-yet>}"
echo ""
echo ""Visit the application in your browser at: http://${EXT_ADDR}/""
echo ""
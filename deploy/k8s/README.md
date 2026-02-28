# Chatbot Deployment on K8s

## Requirements

* You must have an Anthropic API key set in your environment which is accessible through `$ANTHROPIC_API_KEY`
* You must have a Brave API key set in your environment which is accessible through `$BRAVE_API_KEY`

You can use the script [./deploy-mcp-demo.sh](./deploy-mcp-demo.sh) to deploy the MCP servers and the demo application.

### Description of things the script does:

* Creates a Kubernetes namespace for this demo: we are using `mcp-demo` throughout these instructions
* Installs a few [MCP servers](https://mcp.acuvity.ai/) in the same Kubernetes `mcp-demo` namespace
* Create a `values.yaml` file which describes best all your MCP server setup that you have previously completed. If you have installed the MCP servers within the same namespace from the Acuvity MCP registry as where you are planning to install this demo application, then you can match the `name` to its Kubernetes service name and leave the `host` field empty like in this example below as the URL will be automatically completed within the helm chart otherwise fill out the host to the URL of your MCP server like for example: `http://github.mcp-servers.svc.cluster.local:8000/sse`.

```yaml
mcpServers:
  - name: mcp-server-fetch
    host:
  - name: mcp-server-brave-search
    host:
  - name: mcp-server-memory
    host:
  - name: mcp-server-sequential-thinking
    host:
```

* Install the demo application with the command:

```console
helm -n mcp-demo install mcp-demo charts/mcp-demo -f values.yaml --set secrets.anthropic_key=$ANTHROPIC_API_KEY
```

## Access the application

If you have installed the services from the application with their currently recommended default settings (type `ClusterIP`), then you will need to port forward to the application services so that you can access the application.
The instructions for that are displayed in the terminal at installation time.
However, in case you have left the service port numbers at their default settings, you can run the following commands in separate terminal windows:

```console
kubectl -n mcp-demo port-forward svc/mcp-demo-ui 3000
kubectl -n mcp-demo port-forward svc/mcp-demo-agent 8000
```

**NOTE:** Keep the port-forwarding running while you access the application.

Now you can open a browser and access the application at: http://localhost:3000/

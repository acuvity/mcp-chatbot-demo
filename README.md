# Chatbot example with agentic workflows

## Installation and Setup

### Getting started

- Clone the repository:

  ```bash
  git clone <repository-url>
  ```

### Deploying this on K8s

Follow the instructions [here](./deploy/k8s/README.md)

### Trying out the application with Docker Compose

Follow the instructions [here](./deploy/compose/README.md#trying-out-the-application-with-docker)

### Developing ui and agent (using Docker compose)

Follow the instructions [here](./deploy/compose/README.md#developing-ui-and-agent)

### Support for TLS

> [!TIP]
> For ease of use, we are using [tg](https://github.com/acuvity/tg) which is a simple
> TLS generator CLI: `tg cert --name server --ip 127.0.0.1 --dns localhost`

> [!WARNING]
> The certificates provided are only for ease of use and MUST not be used in production.

All certificates for MCP servers already exist in certs folder. You can update the `certs/init-certs.sh`

## API Endpoints

- **GET /health**: Health check endpoint
- **POST /api/v1/chat**: Send a message to the chat API
- **GET /api/v1/conversations**: Get all conversations for the current user
- **GET /api/v1/conversations/{conversation_id}/messages**: Get all messages for a specific conversation

## Running Tests

```bash
pytest
```

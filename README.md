# Chatbot example with agentic workflows

## Installation and Setup

### Getting started

- Clone the repository:

  ```bash
  git clone <repository-url>
  ```

- Create a `.env` file based on the provided template:

  ```bash
  cp .env.template .env
  ```

- Update the environment variables as needed.

### Trying out the application with Docker Compose

Follow the instructions [here](./deploy/compose/README.md#trying-out-the-application-with-docker)

### Deploying this on K8s

Follow the instructions [here](./deploy/k8s/README.md)

### Developing ui and agent (using Docker compose)

Follow the instructions [here](./deploy/compose/README.md#developing-ui-and-agent)

## API Endpoints

- **GET /health**: Health check endpoint
- **POST /api/v1/chat**: Send a message to the chat API
- **GET /api/v1/conversations**: Get all conversations for the current user
- **GET /api/v1/conversations/{conversation_id}/messages**: Get all messages for a specific conversation

## Running Tests

```bash
pytest
```

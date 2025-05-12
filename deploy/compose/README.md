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

### Trying out the application with Docker

- Start the Docker containers:

  ```bash
  docker compose up -d
  ```

- The `UI` will be available at http://localhost:3000 and the `API` at http://localhost:8000

- Remove all containers and volumes:

  ```bash
  docker compose down --volumes
  ```


### Deploying this in production internally

- Requirements
  K8s cluster

### Developing ui and agent

- Start the Docker containers:

  ```bash
  docker compose -f docker-compose-dev.yml up -d
  ```

  The local filesystem is mounted in the containers and on changing files the `UI` and `Agent` reload.

## API Endpoints

- **GET /health**: Health check endpoint
- **POST /api/v1/chat**: Send a message to the chat API
- **GET /api/v1/conversations**: Get all conversations for the current user
- **GET /api/v1/conversations/{conversation_id}/messages**: Get all messages for a specific conversation

## Running Tests

```bash
pytest
```

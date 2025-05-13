# Chatbot example with agentic workflows on docker compose

NOTE: All commands here must be run in the deploy/compose directory

- Create a `.env` file based on the provided template:

  ```bash
  cp .env.template .env
  ```

- Update the environment variables as needed.

## Trying out the application with Docker

- Start the Docker containers:

  ```bash
  docker compose -f docker-compose.yml up -d
  ```

- Start the Docker containers with TLS:

In this mode, the following will happen:
  - UI talks to API using TLS. For this, your system or browser will need to trust the [CA root](../../certs/ca-root-cert.pem)
  - API/Agent service will talk to all MCP servers using TLS

  ```bash
  docker compose -f docker-compose.yml -f docker-compose.tls.yml up -d
  ```

- The `UI` will be available at http://localhost:3000 and the `API` at http://localhost:8000

- Remove all containers and volumes:

  ```bash
  docker compose down --volumes
  ```


## Developing ui and agent

- Start the Docker containers:

  ```bash
  docker compose -f docker-compose-dev.yml up -d
  ```

  The local filesystem is mounted in the containers and on changing files the `UI` and `Agent` reload.


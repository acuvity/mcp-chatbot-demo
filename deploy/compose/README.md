# Chatbot example with agentic workflows on docker compose

## Trying out the application with Docker

- Start the Docker containers:

  ```bash
  docker compose up -d
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


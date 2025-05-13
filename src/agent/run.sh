#!/bin/bash

set -e

if [ ! -z "${AGENT_TLS_CAFILE}" ]; then
  echo "Adding CA file: ${AGENT_TLS_CAFILE}"
  cat /etc/ssl/certs/ca-certificates.crt ${AGENT_TLS_CAFILE} > /tmp/ca-certificates.crt
  export SSL_CERT_FILE=/tmp/ca-certificates.crt
  export REQUESTS_CA_BUNDLE=/tmp/ca-certificates.crt
fi

if [ "${AGENT_TLS_SERVER_ENABLE}" = "true" ]; then
  echo "Using server cert: ${AGENT_TLS_SERVER_CERT} key: ${AGENT_TLS_SERVER_KEY}"
  # Run migrations first
  alembic upgrade head &&
  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload --ssl-certfile ${AGENT_TLS_SERVER_CERT} --ssl-keyfile ${AGENT_TLS_SERVER_KEY}
else
  # Run migrations first
  alembic upgrade head &&
  uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
fi
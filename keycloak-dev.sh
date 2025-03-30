#!/bin/bash

set -e

KEYCLOAK_IMAGE="quay.io/keycloak/keycloak:24.0.1"
CONTAINER_NAME="keycloak-dev"
REALM_NAME="dev-realm"
EXPORT_DIR="./keycloak-config"
REALM_FILE="$EXPORT_DIR/realm-export.json"
KEYCLOAK_PORT=9000
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

function create_realm_file() {
  echo "🧹 Cleaning old config folder..."
  rm -rf "$EXPORT_DIR"
  mkdir -p "$EXPORT_DIR"

  echo "📝 Creation of file $REALM_FILE ..."
  cat > "$REALM_FILE" <<EOF
{
  "realm": "$REALM_NAME",
  "enabled": true,
  "users": [
    {
      "username": "dev-user",
      "enabled": true,
      "emailVerified": true,
      "firstName": "Dev",
      "lastName": "User",
      "email": "dev.user@example.com",
      "credentials": [
        {
          "type": "password",
          "value": "password",
          "temporary": false
        }
      ],
      "realmRoles": ["user"]
    }
  ],
  "roles": {
    "realm": [
      {
        "name": "user"
      }
    ]
  },
  "clients": [
    {
      "clientId": "dev-client",
      "publicClient": true,
      "redirectUris": ["http://localhost:8081/*"],
      "directAccessGrantsEnabled": true,
      "standardFlowEnabled": true,
      "enabled": true
    }
  ]
}
EOF
}

function start_keycloak() {
  if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    echo "⚠️ The container '$CONTAINER_NAME' already exists. Stop it with './keycloak-dev.sh stop'."
    exit 1
  fi

  create_realm_file

  echo "🚀 Starting keycloak in background on http://localhost:$KEYCLOAK_PORT ..."
  docker run -d --rm \
    --name "$CONTAINER_NAME" \
    -p $KEYCLOAK_PORT:8080 \
    -e KEYCLOAK_ADMIN=$ADMIN_USER \
    -e KEYCLOAK_ADMIN_PASSWORD=$ADMIN_PASSWORD \
    -v "$(pwd)/$EXPORT_DIR":/opt/keycloak/data/import \
    $KEYCLOAK_IMAGE \
    start-dev --import-realm

  echo "✅ Keycloak is started in container '$CONTAINER_NAME'."
}

function stop_keycloak() {
  if docker ps --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}\$"; then
    echo "🛑 Stoping the keycloak container..."
    docker stop "$CONTAINER_NAME"
  else
    echo "ℹ️ The container '$CONTAINER_NAME' is not running."
  fi
}

case "$1" in
  start)
    start_keycloak
    ;;
  stop)
    stop_keycloak
    ;;
  *)
    echo "Usage: $0 {start|stop}"
    exit 1
    ;;
esac

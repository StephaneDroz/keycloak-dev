#!/bin/bash

# === Configuration ===
KEYCLOAK_URL="http://localhost:9000"
REALM="dev-realm"
CLIENT_ID="dev-client"
USERNAME="dev-user"
PASSWORD="password"

# === Dependencies check ===
if ! command -v jq >/dev/null 2>&1; then
  echo "❌ 'jq' is required but not installed. Please install it (e.g. 'sudo apt install jq')."
  exit 1
fi

# === Request token ===
echo "🔐 Requesting token from $KEYCLOAK_URL/realms/$REALM..."

RESPONSE=$(curl -s -X POST "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=$CLIENT_ID" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD")

echo "$RESPONSE"

# === Extract and display token ===
ACCESS_TOKEN=$(echo "$RESPONSE" | jq -r .access_token)

if [[ "$ACCESS_TOKEN" == "null" ]]; then
  echo "❌ Failed to retrieve access token. Response:"
  echo "$RESPONSE"
  exit 1
fi

echo "✅ Access token:"
echo "$ACCESS_TOKEN"

#!/usr/bin/env bash
set -Eeuo pipefail

NETWORK_NAME="backend-api"
NETWORK_SUBNET="172.19.0.0/16"
ENV_EXAMPLE=".env.example"
ENV_FILE=".env"
JWT_KEY="JWT_SECRET"

# 1. Create Docker network if it doesn't exist
if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
    echo "Docker network '$NETWORK_NAME' already exists."
else
    docker network create \
        --driver bridge \
        --subnet "$NETWORK_SUBNET" \
        "$NETWORK_NAME"
    echo "Docker network '$NETWORK_NAME' created."
fi

# 2. Create .env from .env.example if missing
if [[ ! -f "$ENV_FILE" ]]; then
    if [[ ! -f "$ENV_EXAMPLE" ]]; then
        echo "Error: $ENV_EXAMPLE not found." >&2
        exit 1
    fi

    cp "$ENV_EXAMPLE" "$ENV_FILE"
    echo "Created $ENV_FILE from $ENV_EXAMPLE."
else
    echo "$ENV_FILE already exists; preserving other settings."
fi

# 3. Generate a cryptographically secure JWT secret
JWT_SECRET="$(openssl rand -hex 32)"

# 4. Update or append JWT_SECRET in .env
if grep -qE "^${JWT_KEY}=" "$ENV_FILE"; then
    sed -i "s|^${JWT_KEY}=.*|${JWT_KEY}=${JWT_SECRET}|" "$ENV_FILE"
else
    printf '\n%s=%s\n' "$JWT_KEY" "$JWT_SECRET" >> "$ENV_FILE"
fi

# 5. Restrict access to the environment file
chmod 600 "$ENV_FILE"

echo "JWT secret generated and written to $ENV_FILE."
echo "Setup complete."
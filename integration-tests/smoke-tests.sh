#!/usr/bin/env bash

set -euo pipefail

: "${STAGING_BASE_URL:?STAGING_BASE_URL is required}"

echo "Running staging smoke tests..."
echo "Base URL: ${STAGING_BASE_URL}"

# Remove trailing slash
STAGING_BASE_URL="${STAGING_BASE_URL%/}"

echo ""
echo "==> Checking API Gateway health"

curl --fail --silent --show-error \
  --max-time 15 \
  "${STAGING_BASE_URL}/actuator/health" \
  > /tmp/api-gateway-health.json

echo "API Gateway is healthy."

echo ""
echo "==> Checking authentication endpoint"

HTTP_STATUS=$(curl \
  --silent \
  --show-error \
  --output /dev/null \
  --write-out "%{http_code}" \
  --max-time 15 \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "email": "invalid-smoke-test@example.com",
    "password": "invalid-password"
  }' \
  "${STAGING_BASE_URL}/auth/login")

if [ "$HTTP_STATUS" != "401" ]; then
  echo "Authentication smoke test failed."
  echo "Expected HTTP 401, got HTTP ${HTTP_STATUS}"
  exit 1
fi

echo "Authentication endpoint is responding correctly."

echo ""
echo "==> Checking protected patient endpoint"

HTTP_STATUS=$(curl \
  --silent \
  --show-error \
  --output /dev/null \
  --write-out "%{http_code}" \
  --max-time 15 \
  "${STAGING_BASE_URL}/api/patients")

if [ "$HTTP_STATUS" != "401" ]; then
  echo "Protected endpoint smoke test failed."
  echo "Expected HTTP 401, got HTTP ${HTTP_STATUS}"
  exit 1
fi

echo "Protected patient endpoint is responding correctly."

echo ""
echo "======================================"
echo "Staging smoke tests passed."
echo "======================================"
#!/usr/bin/env bash
#set -euo pipefail

service="${1:-}"

if [[ -z "$service" ]]; then
  echo "Usage: $0 <service>"
  exit 1
fi

STATE_DIR=".staging-state"
ROLLBACK_FILE="${STATE_DIR}/rollback.env"

if [[ ! -f "$ROLLBACK_FILE" ]]; then
  echo "ERROR: ${ROLLBACK_FILE} does not exist."
  exit 1
fi

case "$service" in
  api-gateway)
    digest_var="API_GATEWAY_DIGEST"
    ;;
  patient-service)
    digest_var="PATIENT_SERVICE_DIGEST"
    ;;
  billing-service)
    digest_var="BILLING_SERVICE_DIGEST"
    ;;
  auth-service)
    digest_var="AUTH_SERVICE_DIGEST"
    ;;
  analytics-service)
    digest_var="ANALYTICS_SERVICE_DIGEST"
    ;;
  *)
    echo "ERROR: Unknown service: $service"
    exit 1
    ;;
esac

rollback_digest=$(grep "^${digest_var}=" "$ROLLBACK_FILE" | cut -d= -f2-)

if [[ -z "$rollback_digest" ]]; then
  echo "ERROR: No rollback digest found for ${service}."
  exit 1
fi

echo "Rolling back ${service}"
echo "Digest: ${rollback_digest}"

# Load normal Compose configuration and the current release.
set -a
source .env
source "${STATE_DIR}/release.env"
set +a

# Override ONLY the failed service's digest.
export "${digest_var}=${rollback_digest}"

echo ""
echo "Pulling rollback image..."
docker compose pull "$service"

echo ""
echo "Starting rollback..."
docker compose up -d --no-deps "$service"

echo ""
echo "Waiting for ${service} to become healthy..."

for i in $(seq 1 36); do
  health=$(docker inspect "$service" \
    --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' \
    2>/dev/null || echo "missing")

  echo "Attempt ${i}/36: ${health}"

  if [[ "$health" == "healthy" ]]; then
    echo "${service} rollback successful."
    exit 0
  fi

  if [[ "$health" == "unhealthy" || "$health" == "missing" || "$health" == "no-healthcheck" ]]; then
    break
  fi

  sleep 10
done

echo ""
echo "ERROR: ${service} rollback failed."
docker compose ps "$service"
docker compose logs --tail=100 "$service"

exit 1
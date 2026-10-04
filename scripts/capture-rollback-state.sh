#!/usr/bin/env bash
set -euo pipefail

STATE_DIR=".staging-state"
ROLLBACK_FILE="${STATE_DIR}/rollback.env"

mkdir -p "$STATE_DIR"

cat > "${ROLLBACK_FILE}.new" <<EOF
API_GATEWAY_DIGEST=$(docker image inspect "$(docker inspect api-gateway --format '{{.Config.Image}}')" --format '{{index .RepoDigests 0}}' | sed 's/.*@//')
PATIENT_SERVICE_DIGEST=$(docker image inspect "$(docker inspect patient-service --format '{{.Config.Image}}')" --format '{{index .RepoDigests 0}}' | sed 's/.*@//')
BILLING_SERVICE_DIGEST=$(docker image inspect "$(docker inspect billing-service --format '{{.Config.Image}}')" --format '{{index .RepoDigests 0}}' | sed 's/.*@//')
AUTH_SERVICE_DIGEST=$(docker image inspect "$(docker inspect auth-service --format '{{.Config.Image}}')" --format '{{index .RepoDigests 0}}' | sed 's/.*@//')
ANALYTICS_SERVICE_DIGEST=$(docker image inspect "$(docker inspect analytics-service --format '{{.Config.Image}}')" --format '{{index .RepoDigests 0}}' | sed 's/.*@//')
EOF

mv "${ROLLBACK_FILE}.new" "$ROLLBACK_FILE"

echo "Rollback state captured:"
cat "$ROLLBACK_FILE"

#!/usr/bin/env bash
#set -euo pipefail

: "${DOCKERHUB_USERNAME:?DOCKERHUB_USERNAME is required}"
: "${IMAGE_TAG:?IMAGE_TAG is required}"

STATE_DIR=".staging-state"
RELEASE_FILE="${STATE_DIR}/release.env"

mkdir -p "$STATE_DIR"

echo "Preparing release: ${IMAGE_TAG}"

services=(
  api-gateway
  patient-service
  billing-service
  auth-service
  analytics-service
)

export DOCKERHUB_USERNAME=oxblixxx

for service in "${services[@]}"; do
  image="${DOCKERHUB_USERNAME}/${service}:${IMAGE_TAG}"

  echo "Pulling ${image}..."
  docker pull "$image"
done

cat > "${RELEASE_FILE}.new" <<EOF
API_GATEWAY_DIGEST=$(docker image inspect "${DOCKERHUB_USERNAME}/api-gateway:${IMAGE_TAG}" --format '{{index .RepoDigests 0}}' | sed 's/.*@//')
PATIENT_SERVICE_DIGEST=$(docker image inspect "${DOCKERHUB_USERNAME}/patient-service:${IMAGE_TAG}" --format '{{index .RepoDigests 0}}' | sed 's/.*@//')
BILLING_SERVICE_DIGEST=$(docker image inspect "${DOCKERHUB_USERNAME}/billing-service:${IMAGE_TAG}" --format '{{index .RepoDigests 0}}' | sed 's/.*@//')
AUTH_SERVICE_DIGEST=$(docker image inspect "${DOCKERHUB_USERNAME}/auth-service:${IMAGE_TAG}" --format '{{index .RepoDigests 0}}' | sed 's/.*@//')
ANALYTICS_SERVICE_DIGEST=$(docker image inspect "${DOCKERHUB_USERNAME}/analytics-service:${IMAGE_TAG}" --format '{{index .RepoDigests 0}}' | sed 's/.*@//')
EOF

mv "${RELEASE_FILE}.new" "$RELEASE_FILE"

echo ""
echo "Release digests:"
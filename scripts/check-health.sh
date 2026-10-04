#!/usr/bin/env bash

core_services=(
  patient-service
  billing-service
  auth-service
  analytics-service
)

api_gateway="api-gateway"

TIMEOUT="${HEALTH_TIMEOUT:-600}"
INTERVAL="${HEALTH_INTERVAL:-10}"
STATE_FILE=".staging-state/failed-services.txt"

mkdir -p .staging-state
: > "$STATE_FILE"

check_health() {
  local service="$1"

  docker inspect "$service" \
    --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' \
    2>/dev/null || echo "missing"
}

wait_for_core_services() {
  local start_time=$SECONDS

  echo ""
  echo "======================================"
  echo "Waiting for core services"
  echo "======================================"

  while true; do
    all_healthy=true
    failed_services=()

    echo ""
    echo "===== Core service health ====="

    for service in "${core_services[@]}"; do
      health=$(check_health "$service")

      echo "${service}: ${health}"

      case "$health" in
        healthy)
          ;;

        starting)
          all_healthy=false
          ;;

        unhealthy|missing|no-healthcheck)
          failed_services+=("$service")
          all_healthy=false
          ;;

        *)
          all_healthy=false
          ;;
      esac
    done

    # All four are healthy.
    if $all_healthy; then
      echo ""
      echo "All core services are healthy."
      return 0
    fi

    # A core service has definitively failed.
    if ((${#failed_services[@]} > 0)); then
      echo ""
      echo "Core service failure detected."

      printf '%s\n' "${failed_services[@]}" > "$STATE_FILE"

      echo ""
      echo "Services to roll back:"
      cat "$STATE_FILE"

      return 1
    fi

    # Still starting.
    if (( SECONDS - start_time >= TIMEOUT )); then
      echo ""
      echo "Core service health check timed out."

      # Capture anything that is still not healthy.
      : > "$STATE_FILE"

      for service in "${core_services[@]}"; do
        health=$(check_health "$service")

        if [[ "$health" != "healthy" ]]; then
          echo "$service" >> "$STATE_FILE"
        fi
      done

      return 1
    fi

    sleep "$INTERVAL"
  done
}

wait_for_api_gateway() {
  local start_time=$SECONDS

  echo ""
  echo "======================================"
  echo "Waiting for API Gateway"
  echo "======================================"

  while true; do
    health=$(check_health "$api_gateway")

    echo "${api_gateway}: ${health}"

    case "$health" in
      healthy)
        echo ""
        echo "API Gateway is healthy."
        return 0
        ;;

      unhealthy|missing|no-healthcheck)
        echo ""
        echo "API Gateway failed health check."

        echo "$api_gateway" > "$STATE_FILE"

        return 1
        ;;

      starting)
        ;;
    esac

    if (( SECONDS - start_time >= TIMEOUT )); then
      echo ""
      echo "API Gateway health check timed out."

      echo "$api_gateway" > "$STATE_FILE"

      return 1
    fi

    sleep "$INTERVAL"
  done
}

# --------------------------------------
# Phase 1: Core services
# --------------------------------------

if ! wait_for_core_services; then
  echo ""
  echo "Core service health validation failed."
  exit 1
fi

# --------------------------------------
# Phase 2: API Gateway
# --------------------------------------

if ! wait_for_api_gateway; then
  echo ""
  echo "API Gateway health validation failed."
  exit 1
fi

echo ""
echo "======================================"
echo "All services are healthy."
echo "======================================"
exit 0
#!/bin/bash
# network-engine/lib/services.sh
# lib/services.sh

SERVICES=()

ensure_service() {
  local svc="$1"
  local conf="$BASE_DIR/topology/services/$svc/service.conf"

  [[ -f "$conf" ]] || return 0

  source "$conf"

  ns_exists "$SERVICE_NAMESPACE" || return 1

  ip netns exec "$SERVICE_NAMESPACE" mkdir -p "$SERVICE_ROOT"

  ip netns exec "$SERVICE_NAMESPACE" cp \
    "$BASE_DIR/topology/services/$svc/index.html" \
    "$SERVICE_ROOT/index.html" 2>/dev/null || true

  if ip netns exec "$SERVICE_NAMESPACE" ss -tln | grep -q ":$SERVICE_PORT"; then
    return 0
  fi

  ip netns exec "$SERVICE_NAMESPACE" bash -c \
    "cd $SERVICE_ROOT && nohup $SERVICE_CMD > service.log 2>&1 &"
}

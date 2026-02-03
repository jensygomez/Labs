#!/bin/bash
# network-engine/engine.sh
set -Eeuo pipefail
[[ "${DEBUG:-0}" == "1" ]] && set -x

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/lib/guard.sh"
source "$BASE_DIR/lib/idempotency.sh"

require_root

run() {
  local phase="$1"
  source "$BASE_DIR/phases/$phase"

  declare -F run_phase >/dev/null \
    || { echo "❌ $phase no define run_phase()"; exit 1; }

  run_phase
  unset -f run_phase
}


run 01-netns.sh
run 02-links.sh
run 03-addressing.sh
run 04-routing.sh
run 05-forwarding.sh
run 06-nat.sh
run 07-vlan.sh
run 08-firewall.sh
run 100-trace-test.sh


echo "✅ Topología convergida"

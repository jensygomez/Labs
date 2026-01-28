#!/bin/bash
# network-engine/lib/idempotency.sh
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/topology/lab.conf"



ns_exists() {
  ip netns list | grep -qw "$1"
}

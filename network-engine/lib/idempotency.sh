#!/bin/bash
# network-engine/lib/idempotency.sh

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -Eeuo pipefail

source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/topology/lab.conf"



ns_exists() {
  ip netns list | grep -qw "$1"
}

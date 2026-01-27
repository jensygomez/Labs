#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$BASE_DIR/lib/netns.sh"
source "$BASE_DIR/topology/lab.conf"

set -Eeuo pipefail

ns_exists() {
  ip netns list | grep -qw "$1"
}

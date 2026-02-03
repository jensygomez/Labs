#!/bin/bash
# network-engine/lib/idempotency.sh
ns_exists() {
  ip netns list | grep -qw "$1"
}

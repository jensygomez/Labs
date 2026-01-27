#!/bin/bash

set -Eeuo pipefail

ns_exists() {
  ip netns list | grep -qw "$1"
}

#!/bin/bash
set -euo pipefail

source lib/log.sh
source lib/guard.sh

require_root
require_tools ip iptables

run_phase 01-netns
run_phase 02-links
run_phase 03-addressing
run_phase 04-forwarding
run_phase 05-routing
run_phase 06-nat
run_phase 07-firewall
run_phase 08-tests

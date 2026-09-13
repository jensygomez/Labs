# 11 - HA & Load Balancing (Category-Specific)
> **Rule:** This file MUST be read when generating incidents for the "HA & Load Balancing" category.

## [BUG-011] Keepalived Split-Brain due to Firewalld VRRP blocking
- **Symptom:** VIP (`10.10.10.30`) appears on both `lb01` and `lb02` simultaneously. `journalctl -u keepalived` shows "Receive advertisement timeout".
- **Root Cause:** Firewalld is blocking VRRP multicast (Protocol 112). The rich rule `rule protocol value="vrrp" accept` is missing, or the firewalld service was reloaded without `immediate: true`.
- **Fix/Rule:** ALWAYS ensure VRRP is allowed in firewalld for `lb_nodes`. When injecting network isolation for VRRP (to cause split-brain), use `ansible.posix.firewalld` rich rules to DROP protocol 112, not just block TCP/UDP ports.
- **Discovered in:** INC-002 (HA & Load Balancing).

## [BUG-012] `ip_nonlocal_bind` failures in LXC containers
- **Symptom:** Keepalived fails to start or bind the VIP with "Cannot assign requested address".
- **Root Cause:** In LXC containers, `net.ipv4.ip_nonlocal_bind=1` might fail if the container doesn't have nesting features enabled, or if Ansible's `sysctl` module fails on read-only procfs.
- **Fix/Rule:** Use `ansible.posix.sysctl` with `ignoreerrors: yes` for `ip_nonlocal_bind` in LXC environments. When injecting sysctl breaks, revert them carefully.
- **Discovered in:** INC-002 (HA & Load Balancing).

## [BUG-013] HAProxy down but Keepalived VIP remains active
- **Symptom:** VIP is active on a node, but HAProxy service is stopped. Traffic to VIP returns connection refused.
- **Root Cause:** Keepalived is not configured with a `vrrp_script` to track the HAProxy process state (weight -20).
- **Fix/Rule:** Keepalived configs MUST include a `trackScript`. If injecting HAProxy failures, the VIP should float to the backup node. If the incident requires the VIP to stay stuck, disable the track script.
- **Discovered in:** INC-002 (HA & Load Balancing).

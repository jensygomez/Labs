# 05 - Networking, DNS & Firewalld (Category-Specific)
> **Rule:** This file MUST be read when generating incidents involving network connectivity, firewalld, or DNS resolution.

## [BUG-005A] Firewalld state desync (immediate vs permanent)
- **Symptom:** The incident injection works temporarily, but disappears after a node reboot, OR the rule doesn't take effect until a manual `firewall-cmd --reload` (which might restart dependent services and mask the incident).
- **Root Cause:** Using `ansible.posix.firewalld` with only `permanent: true` (requires reload) or only `immediate: true` (lost on reboot).
- **Fix/Rule:** ALWAYS use BOTH `permanent: true` AND `immediate: true` together when injecting or recovering firewalld rules in incident playbooks. This ensures the fault is immediate for the practitioner, but also persists across lab rebuilds.
- **Discovered in:** INC-008 (Networking & Firewall).

## [BUG-005B] Ephemeral SELinux decoys using `chcon`
- **Symptom:** A decoy involving SELinux contexts disappears after a reboot or a `restorecon` command, leaving the recovery playbook unable to "fix" it or the practitioner confused.
- **Root Cause:** Using `ansible.builtin.command: cmd: "chcon ..."` modifies the context only in memory. It is not persistent.
- **Fix/Rule:** If using SELinux context changes as a decoy, you MUST use `ansible.builtin.command: cmd: "semanage fcontext -a -t <type> '<path>(/.*)?'"` followed by `restorecon -Rv <path>`. The recovery playbook MUST explicitly run `restorecon -Rv <path>` to clean it up. Do not rely on `chcon` unless the recovery explicitly cleans it.
- **Discovered in:** INC-008 (Networking & Firewall).

## [BUG-005C] Asymmetric network faults require dynamic targeting
- **Symptom:** A network fault (like blocking a port) is applied to all nodes in a group, making the issue obvious and trivial, rather than requiring correlation.
- **Root Cause:** Running firewalld tasks directly on `hosts: app_nodes` without isolating a single target.
- **Fix/Rule:** For L2 incidents, use the `set_fact` + `add_host` pattern on `localhost` to select a single random node, then run the firewalld injection ONLY on that dynamic group (e.g., `incident_008_target`). 
- **Discovered in:** INC-008 (Networking & Firewall).

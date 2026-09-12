# 08 - Authentication & Identity (Category-Specific)
> **Rule:** This file MUST be read when generating incidents for the "Authentication & Identity" category. It contains patterns for user state, PAM, SSH, and cluster asymmetry discovered in this lab.

## [BUG-010A] Asymmetric authentication state in HA clusters
- **Symptom:** A user can authenticate from some application nodes but gets rejected by others, causing intermittent login failures when traffic is load-balanced.
- **Root Cause:** Authentication state (e.g., locked/expired user, modified SSH keys, or PAM configs) was changed on only one node in the cluster, not all.
- **Fix/Rule:** When injecting auth issues in an HA cluster, explicitly decide if it's a *cluster-wide* issue or an *asymmetric* issue. If asymmetric, use the `set_fact` + `add_host` pattern to target a single random node. The recovery playbook must scan all nodes using a marker file to find and fix the specific affected node.
- **Discovered in:** INC-010 (Authentication & Identity).

## [BUG-010B] Control node lacks DNS resolution for troubleshooting
- **Symptom:** Troubleshooting from the control node fails because it cannot resolve lab node hostnames, even though the `dns01.yml` playbook was executed.
- **Root Cause:** `dns01.yml` targets `hosts: all` (the remote inventory), not `localhost`. The control node's `/etc/hosts` is not updated.
- **Fix/Rule:** If an incident requires DNS resolution from the control node, Play 1 of the incident must use `blockinfile` with a unique marker (e.g., `# {mark} ANSIBLE MANAGED HOSTS (SYSTECH CONTROL NODE)`) on `hosts: localhost`. The recovery playbook MUST clean up this specific block using `state: absent` and the exact same marker.
- **Discovered in:** INC-010 (Authentication & Identity).

## [BUG-010C] Decoy cleanup in authentication incidents
- **Symptom:** Recovery playbook fixes the main auth issue, but the node remains "dirty" with fake logs and misleading configs, breaking future incidents or baseline checks.
- **Root Cause:** The injection playbook creates realistic decoys (fake PAM logs, misleading `/etc/passwd` comments, `.bashrc` warnings), but the recovery playbook forgets to remove them.
- **Fix/Rule:** Every decoy injected must have a symmetric removal task in the recovery playbook. Use `ansible.builtin.file: state: absent` for fake logs (e.g., `/var/log/security_audit.log`) and `ansible.builtin.lineinfile: state: absent` for `.bashrc` entries. Use `ansible.builtin.user: comment: ""` to restore `/etc/passwd` fields.
- **Discovered in:** INC-010 (Authentication & Identity).

## [BUG-010D] Verifying user state post-recovery
- **Symptom:** Recovery playbook reports "changed" and succeeds, but the user is still effectively locked or expired due to OS-level caching or incomplete module execution.
- **Root Cause:** Relying only on Ansible module return values without verifying the actual OS state.
- **Fix/Rule:** Always include a verification step in the recovery playbook using `passwd -S <user>` and `chage -l <user>`. Register the output to variables and display them in a final summary debug task to prove the account is truly active and not expired.
- **Discovered in:** INC-010 (Authentication & Identity).

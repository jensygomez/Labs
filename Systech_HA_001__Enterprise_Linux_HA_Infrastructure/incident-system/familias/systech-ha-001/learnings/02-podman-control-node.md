# 02 - Podman Control Node Quirks (Cross-Cutting)
> **Rule:** This file MUST be read for EVERY incident generation. It contains specific quirks related to the Podman rootless control node and LXC networking.

## [BUG-005] SSH Key Permissions in Rootless Podman
- **Symptom:** SSH connections from the control node fail with "Permissions 0644 are too open" or similar.
- **Root Cause:** Rootless Podman maps UIDs. If the SSH key is mounted with host root ownership, the container's non-root user cannot read it properly.
- **Fix/Rule:** Ensure SSH keys are generated *inside* the container's entrypoint or mounted with explicit `uid=1000,gid=1000` in the `podman run` command.
- **Discovered in:** INC-007 (Authentication & Identity).

## [BUG-006] ZeroTier Overlay Routing to Lab Intranet
- **Symptom:** The control node can ping Proxmox API but cannot reach the lab nodes (`10.10.10.0/24`).
- **Root Cause:** The lab intranet is isolated within Proxmox. The host machine needs a static route to forward traffic from the ZeroTier interface to the Proxmox bridge.
- **Fix/Rule:** This is a host-level configuration (`sudo ip route add 10.10.10.0/24 via 10.147.17.100`), not an Ansible task for the lab nodes. The `PROMPT_GENERACION` must not attempt to fix routing via Ansible on the lab nodes.
- **Discovered in:** INC-008 (Networking & Firewall).

## [BUG-007] Modifying `/etc/hosts` on Podman Control Node (Ephemeral + Atomic Write Failures)
- **Symptom:** 
  1. Changes to `/etc/hosts` revert after reboot (ephemeral tmpfs/bind-mount).
  2. `OSError: [Errno 16] Device or resource busy` when using `blockinfile` (even with `state: absent`).
- **Root Cause:** `/etc/hosts` is a bind-mount managed by the container runtime. Ansible's default atomic write (write-to-temp + rename) fails because the kernel forbids `rename()` on bind-mounted files.
- **Fix/Rule:** 
  1. ALWAYS use `ansible.builtin.blockinfile` with a highly specific, unique marker (e.g., `# {mark} ANSIBLE MANAGED HOSTS (SYSTECH CONTROL NODE)`). The recovery playbook MUST clean this block using `state: absent`.
  2. ALWAYS add `unsafe_writes: yes` to the `blockinfile` task (both for injection and recovery) to bypass the atomic rename failure.
  3. ALWAYS use the exact Jinja2 loop from `dns01.yml` iterating over `groups['all']` (with the `if hostvars[host].ansible_host is defined` check). Never restrict the Control Node's DNS resolution to just the incident's target group.
- **Discovered in:** INC-001 (Authentication & Identity).

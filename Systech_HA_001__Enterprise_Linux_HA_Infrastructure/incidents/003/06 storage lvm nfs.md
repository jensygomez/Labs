# 06 - Storage, LVM & NFS (Category-Specific)
> **Rule:** This file MUST be read when generating incidents involving LVM, filesystems, or NFS storage/export/mount behavior.

## [BUG-014] JSON booleans must never be rendered as Jinja strings
- **Symptom:** State file consumers (recovery playbook, external tooling) parse `"decoy_applied": "true"` as a truthy *string* even when the value should logically be `false`, because any non-empty string is truthy in most languages/Jinja contexts.
- **Root Cause:** Writing `"decoy_applied": "{{ some_boolean_expression }}"` (with quotes) always produces a valid, non-empty JSON string — Jinja never gets the chance to omit or falsify it.
- **Fix/Rule:** Always render lifecycle booleans in state JSON WITHOUT surrounding quotes, using the explicit ternary: `"decoy_applied": {{ 'true' if (condition) else 'false' }}`. This is now the mandatory pattern for every boolean field in every `state_file`.
- **Discovered in:** INC-003 (Storage & Filesystems).

## [BUG-015] `local_lock` mount option breaks cross-node NFS advisory locking without touching the server
- **Symptom:** Concurrent writers on different NFS clients (e.g. multiple `app_nodes` writing to the same shared export) intermittently corrupt the same file, even though each individual client believes its `flock()`/`fcntl()` call succeeded.
- **Root Cause:** The NFS client mount option `local_lock` (values: `none` (default) | `all` | `flock` | `posix`) controls whether lock requests are sent to the NFS server (`local_lock=none`, the correct/default behavior for shared writable exports) or resolved purely in the local client kernel (`local_lock=all`). When set to `all`, locks are never visible to other clients mounting the same export, defeating the purpose of advisory locking on shared storage.
- **Fix/Rule:** Never allow `local_lock=all|flock|posix` on any shared, multi-writer NFS mount in this lab (`/var/www/html`, `/var/lib/pgsql/data`). To simulate this class of incident, remount with `mount -o remount,local_lock=all <mountpoint>` and recover with `mount -o remount,local_lock=none <mountpoint>`. Detect current state with `findmnt -no OPTIONS <mountpoint>` rather than assuming state — remounts on already-correct mounts should be skipped for idempotency.
- **Discovered in:** INC-003 (Storage & Filesystems).

## [BUG-016] `target_service` for NFS-*client* incidents should be the consumer service, not `nfs-server`
- **Symptom:** Naively setting `target_service: "nfs"` on `app_nodes` causes the mandatory pre-flight health check (`ansible.builtin.systemd` + `ActiveState != "active"`) to fail, because `app_nodes` are NFS *clients* — the `nfs-server` unit only exists on `storage01`.
- **Root Cause:** The generic incident skeleton's `target_service` placeholder assumes the broken service and the "service to health-check/restart" are the same thing. For storage incidents where the fault is in how a client *consumes* NFS (not in the NFS server itself), the correct `target_service` is the application service that depends on the mount (e.g. `httpd`), not the storage protocol's own daemon.
- **Fix/Rule:** When the injection target is a client-side mount/lock/protocol behavior rather than the storage server itself, set `target_service` to the consuming application service on the affected node group, and reserve `nfs-server`-style values for incidents that target `storage01` directly.
- **Discovered in:** INC-003 (Storage & Filesystems).

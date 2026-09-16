# 06 - Storage, LVM & NFS (Category-Specific)
> **Rule:** This file MUST be read when generating incidents involving LVM, filesystems, or NFS storage/export/mount behavior.

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

## [BUG-017] NFS-specific mount options cannot be changed via `remount`
- **Symptom:** Playbook fails at the remount task with `mount.nfs: an incorrect mount option was specified` (rc 32) when trying to execute `mount -o remount,local_lock=all /var/www/html`.
- **Root Cause:** The Linux kernel does not allow NFS-specific mount options (like `local_lock`, `rsize`, `wsize`, `nfsvers`) to be modified on the fly using the `remount` flag. The `remount` operation only accepts generic VFS options (like `ro`/`rw` or `sync`).
- **Fix/Rule:** To change an NFS-specific mount option dynamically, you must perform a full unmount and mount cycle:
  1. Stop the consuming service (e.g., `httpd`) to prevent "target is busy" errors.
  2. `umount <mountpoint>`
  3. `mount -o <new_options> <source> <mountpoint>` (obtain `<source>` via `findmnt -no SOURCE <mountpoint>`).
  4. Start the consuming service.
- **Discovered in:** INC-003 (Storage & Filesystems) - Injection playbook execution.

## [BUG-018] NFS export directory permissions affect all clients simultaneously
- **Symptom:** All app_nodes can successfully mount the NFS export, but any write operation (touch, mkdir, write to file) fails with "Permission denied" across the entire cluster.
- **Root Cause:** The NFS export directory on the server (`/exports/webdata` on `storage01`) has restrictive permissions (e.g., `0000` or `0700` owned by root). NFS exports inherit the underlying filesystem permissions. Even if the mount options are `rw`, the actual access is governed by the directory permissions on the server side.
- **Fix/Rule:** For shared writable NFS exports, the export directory MUST have permissions `0777` (or appropriate ACLs). When diagnosing "Permission denied" on NFS mounts:
  1. Check mount options with `findmnt` (should show `rw`)
  2. Check the actual directory permissions on the NFS server: `ssh storage01 && ls -ld /exports/webdata`
  3. If permissions are wrong, fix on the server: `chmod 0777 /exports/webdata`
  4. No need to remount on clients — permissions are evaluated on every access.
- **Discovered in:** INC-003 (Storage & Filesystems) - Redesign from client-side mount options to server-side permissions.

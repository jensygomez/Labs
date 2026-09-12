# Architecture Card — SYSTECH-HA-001 Family

> **Purpose:** This document provides the technical context for the AI when generating incidents, recovery playbooks, and spec cards. It defines the topology, node roles, network boundaries, and data flows.
> **Rule for AI:** NEVER hardcode IP addresses or hostnames in generated Ansible playbooks. Always use Ansible inventory groups (`app_nodes`, `lb_nodes`, etc.) and dynamic variables.

## 1. Network Topology & Boundaries
- **Lab Intranet (Proxmox LXC Network):** `10.10.10.0/24` (Where all lab nodes communicate).
- **Management Overlay (ZeroTier):** `10.147.17.0/24` (Used by the Control Node to reach Proxmox API and lab nodes).
- **Floating VIP (Keepalived):** `10.10.10.30` (Points to active `lb01` or `lb02`).
- **Firewall:** `firewalld` is active and enforced on all AlmaLinux 9 nodes.

## 2. Node Inventory & Tier Architecture

### 🟡 Traffic Generators (Simulated Users)
*OS: Ubuntu 24.04 LXC | Group: `client_nodes`*
| Hostname | IP Address | Role & Behavior | Evidence Generated |
| :--- | :--- | :--- | :--- |
| `client01` | 10.10.10.11 | Interactive User (SQL Queries) | `.txt` query results in `/var/www/html/uploads` |
| `client02` | 10.10.10.12 | Background Process (File Writer) | Write logs in `/var/www/html/uploads` |
| `client03` | 10.10.10.13 | Heavy Analytics (Complex Reports) | Tabulated department reports in `/var/www/html/uploads` |
| `client04` | 10.10.10.14 | Batch Consolidator & Rotator | Reads 01/02/03 files, creates `audit_consolidated_*.txt`, deletes old files. |

### 🟢 HA & Load Balancing Tier
*OS: AlmaLinux 9 LXC | Group: `lb_nodes`*
| Hostname | IP Address | Services & Role | Key Configurations |
| :--- | :--- | :--- | :--- |
| `lb01` | 10.10.10.21 | HAProxy (L7) + Keepalived (Master) | `net.ipv4.ip_nonlocal_bind=1`, VRRP priority 100 |
| `lb02` | 10.10.10.22 | HAProxy (L7) + Keepalived (Backup) | `net.ipv4.ip_nonlocal_bind=1`, VRRP priority 90 |

### 🔵 Web App Cluster
*OS: AlmaLinux 9 LXC | Group: `app_nodes`*
| Hostname | IP Address | Services & Role | Mounts & SELinux |
| :--- | :--- | :--- | :--- |
| `app01` | 10.10.10.31 | Apache (httpd) + PHP + php-pgsql | `/var/www/html` (NFSv4), `httpd_use_nfs=on` |
| `app02` | 10.10.10.32 | Apache (httpd) + PHP + php-pgsql | `/var/www/html` (NFSv4), `httpd_use_nfs=on` |
| `app03` | 10.10.10.33 | Apache (httpd) + PHP + php-pgsql | `/var/www/html` (NFSv4), `httpd_use_nfs=on` |

### 🟣 Database Tier
*OS: AlmaLinux 9 LXC | Group: `db_nodes`*
| Hostname | IP Address | Services & Role | Mounts & SELinux |
| :--- | :--- | :--- | :--- |
| `db01` | 10.10.10.40 | PostgreSQL 15 | `/var/lib/pgsql/data` (NFSv4), `postgresql_db_t` context |

### 🔴 Data & Storage Tier
*OS: AlmaLinux 9 VM/LXC | Group: `storage_nodes`*
| Hostname | IP Address | Services & Role | Volumes & Exports |
| :--- | :--- | :--- | :--- |
| `storage01`| 10.10.10.50 | NFSv4 Server (`nfs-server`) | VG: `vg_storage`. Exports: `/exports/webdata`, `/exports/pgdata` |

## 3. Storage & Data Flow Matrix
*All persistent data is centralized on `storage01` via NFSv4 to allow shared state and centralized backups.*

| Source (storage01) | Protocol | Target Mount Point | Consumer Nodes | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `/exports/webdata` | NFSv4 | `/var/www/html` | `app01`, `app02`, `app03` | Shared PHP codebase and user uploads/evidence. |
| `/exports/pgdata` | NFSv4 | `/var/lib/pgsql/data` | `db01` | Centralized PostgreSQL data directory. |

## 4. Automation & Control Plane Context
- **Control Node:** `systech-control` (Podman Rootless container on the physical host). Runs Ansible and OpenTofu.
- **SSH Access:** Ansible connects via SSH keys (`id_systech_control`) to the `ansible` user on all lab nodes.
- **Ansible Playbooks (Deployment Order):**
  1. `storage_setup.yml` (LVM creation, NFS exports, firewalld)
  2. `database_setup.yml` (NFS mount, SELinux contexts, PG init)
  3. `web_app_setup.yml` (NFS mount, SELinux booleans, PHP deploy)
  4. `lb_setup.yml` (sysctl, HAProxy, Keepalived)
  5. `client_setup.yml` / `client0X.yml` (Traffic generator systemd services)

## 5. Critical LXC & OS Quirks (For AI Awareness)
- **LXC `/etc/hosts`:** In some LXC setups (and specifically the Podman control node), `/etc/hosts` is a tmpfs bind-mount. Changes do not persist across reboots unless handled via LXC config or specific Ansible tasks.
- **SELinux:** Enforcing by default on all AlmaLinux 9 nodes. Context mismatches are a primary failure vector.
- **Systemd:** Used for service management on all AlmaLinux 9 and Ubuntu 24.04 nodes.
- **Package Manager:** `dnf` for AlmaLinux 9, `apt` for Ubuntu 24.04.

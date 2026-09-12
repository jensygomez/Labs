# Master Incident Catalog — SYSTECH Project

> **Purpose:** Single source of truth for all troubleshooting incidents across all infrastructure families. 
> **Rule:** This file is updated incrementally. Do not pre-fill 100 rows. Add rows as incidents are defined, generated, and tested.
> **Sorting:** Keep rows ordered by `ID` for quick reference.

## 📖 Status Legend
| Status | Meaning |
| :--- | :--- |
| `PROPOSED` | Spec Card proposed by AI and approved by user. YAML generation pending. |
| `PLANNED` | Idea exists in the backlog. No Spec Card created yet. |
| `SPEC_READY` | Spec Card proposed by AI and approved by user. YAML generation pending. |
| `IN_PROGRESS` | Playbooks generated. Currently being tested/debugged in the lab. |
| `COMPLETE` | Injection and Recovery tested. Ticket generated. Learnings updated. |
| `ARCHIVED` | Deprecated, merged into another incident, or no longer relevant. |

## 📊 Active Catalog

| ID | Family | Category(ies) | Level | Short Title | Difficulty | Status | Target Node(s) | Completion Date |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **INC-001** | systech-ha-001 | Authentication & Identity | L2 | User cannot authenticate (correct password) | 6/10 | PROPOSED | all | 2026-XX-XX |
| **INC-002** | systech-ha-001 | HA & Load Balancing | L2 | VIP appears on both load balancers (split-brain) | 6/10 | PROPOSED | lb_nodes | - |
| **INC-003** | systech-ha-001 | Storage & Filesystems | L2 | Web file writes corrupt intermittently (NFS lock issue) | 6/10 | PROPOSED | app_nodes | - |
| **INC-004** | systech-ha-001 | Security & Auditing | L2 | Suspicious unauthorized SSH access (fail2ban bypass) | 6/10 | PROPOSED | all | - |
| *(Leave blank. Add new rows incrementally as incidents are defined and approved...)* | | | | | | | | |

---

## 📝 Notes & Future Families
- **systech-ha-001:** Current Proxmox/LXC/AlmaLinux HA stack.
- **iac-terraform:** *(Future)* Focus on state drift, provider auth, and module failures.
- **kubernetes:** *(Future)* Focus on pod crashes, CNI issues, and ingress misconfigurations.
- **cloud-localstack:** *(Future)* Focus on AWS API mocking, IAM policies, and S3 bucket policies.

# Spec Card Template — SYSTECH-HA-001

> **Instructions for the AI (Do not delete):** 
> Fill in the blank fields based on the Title and Category provided by the user. 
> DO NOT invent bugs that are already documented in the `learnings/` folder. 
> Keep the injection mechanism abstract (Ansible module/command) without writing the full YAML yet.
> *Note: You may fill the descriptive text fields in Spanish if requested, but all technical terms, commands, and modules must remain in English.*

## 1. Identification
- **Incident ID:** INC-___
- **Family:** systech-ha-001
- **Category(ies):** [e.g., Storage & filesystems, Networking]
- **Level:** L2 (Advanced)
- **Estimated Difficulty:** [X]/10
- **Target Node(s):** [e.g., `storage01`, `db01`, or "Random selection from `app_nodes` group"]
- **Platform Prerequisites:** [e.g., "Requires `storage_setup.yml` role to have run successfully"]

## 2. The Incident (Injection)
- **Visible Symptom (What the "user" reports):** 
  [Describe what the end-user or monitoring system sees. e.g., "Web apps intermittently return 500 Internal Server Error when uploading files."]
  
- **Technical Root Cause (What actually broke):** 
  [Describe the exact change in the system. e.g., "SELinux boolean `httpd_use_nfs` was set to off on the app_nodes."]

- **Injection Mechanism (Ansible/Shell):** 
  [Specify the module or command to use. e.g., "Use `ansible.posix.seboolean` module to disable `httpd_use_nfs`. DO NOT write the full playbook here."]

## 3. Expected Diagnosis (Guide for the practitioner)
- **Expected diagnostic commands:** 
  [e.g., `getsebool -a | grep httpd`, `tail -f /var/log/audit/audit.log`, `mount | grep nfs`]
  
- **Evidence in logs/state:** 
  [e.g., "SELinux audit logs showing denials for `httpd_t` accessing `nfs_t`."]

- **Decoys / Distractions (Optional but recommended for L2):** 
  [e.g., "Simultaneously fill `/var/log` on `app02` with junk data to distract the practitioner toward a disk space issue."]
  *If not applicable, leave blank or write "None".*

## 4. Recovery
- **Expected fix action:** 
  [e.g., "Re-enable the SELinux boolean and make the change persistent with `-P`."]

- **Traceability Table (To be filled during YAML generation):**
  | Injection Task (Incident) | Recovery Task (Fix) | Idempotent (Yes/No) |
  | :--- | :--- | :--- |
  | [Filled when creating _incidente.yml] | [Filled when creating _recuperacion.yml] | [Yes/No] |

## 5. ⚠️ Known Risks to Avoid (Learnings Checklist)
> **Instructions for the AI:** Before proposing this Spec Card, you MUST read `learnings/01-ansible...` and `learnings/02-podman...` (always), and the specific category file for this incident. Mark with an `X` the ones you have verified.

- [ ] **Cross-cutting:** Reviewed `01-ansible-yaml-mecanica.md` (e.g., `random` re-evaluating, handler ordering).
- [ ] **Cross-cutting:** Reviewed `02-podman-control-node.md` (e.g., `/etc/hosts` tmpfs, rootless quirks).
- [ ] **Specific Category:** Reviewed `learnings/XX-[category].md`. Bug avoided: [Name of the bug or "None applicable"].
- [ ] **Specific Category:** Reviewed `learnings/YY-[category].md` (If multi-category). Bug avoided: [Name of the bug or "None applicable"].

## 6. Alignment & Notes
- **Certification Alignment:** [e.g., RHCSA (EX200) - SELinux & Web Services]
- **Complexity / Multi-cause Notes:** [e.g., "This incident is mono-cause but requires understanding the interaction between SELinux and NFS."]

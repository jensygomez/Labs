---
Curso: 100 Days of DevOps
Tema: Day 3 -  Secure Root SSH Access
Fecha de Inicio: 2026-05-28
Dificultad: Básico Medio
Completado: true
tags:
  - DevOps
---
[[Menu 100 Days of DevOps]]




During a technical assessment, I was asked to disable direct root SSH login on the three application servers for security reasons. From a Unix perspective, I consider this a fundamental best practice. The root user should never be directly exposed over the network, as it violates the principle of least privilege and increases the risk of brute-force attacks. Instead, administrators should access the system through regular users and escalate privileges only when necessary using sudo.

I approached the task manually on each server. First, I checked the current SSH configuration, then updated the `PermitRootLogin` directive to `no` using sed, restarted the sshd service, and verified the change. Performing this process one server at a time allowed me to validate each step carefully. After completing the configuration on all three servers, I confirmed that direct root login was no longer possible, while normal user access continued to work without issues.

This exercise reinforced the importance of small but critical security configurations. By disabling direct root access, we significantly reduce the attack surface and encourage more secure operational habits. I believe this type of hardening is essential in any production environment.

---


### **Commands Executed:**

```bash
# Check current configuration
sudo grep -E '^PermitRootLogin' /etc/ssh/sshd_config

# Disable direct root login
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Apply the change by restarting SSH service
sudo systemctl restart sshd

# Verify the configuration was updated
sudo grep -E '^PermitRootLogin' /etc/ssh/sshd_config
```


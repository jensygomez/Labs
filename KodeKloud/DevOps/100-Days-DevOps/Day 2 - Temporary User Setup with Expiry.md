---
Curso: 100 Days of DevOps
Tema: Day 2 - Temporary User Setup with Expiry
Fecha de Inicio: 2026-03-27
Dificultad: Básico Medio
Completado: true
tags:
  - DevOps
---
[[Menu 100 Days of DevOps]]


To fulfill the requirement on **App Server 3** within the Stratos Datacenter, the native `useradd` binary was executed with superuser privileges (`sudo`) to provision the developer account for `james`. By leveraging the long option `--expiredate`, the administrator directly interacts with the Linux identity management subsystem, which performs a background conversion to translate the human-readable `YYYY-MM-DD` date into Unix Epoch time in days (days elapsed since January 1, 1970). This approach ensures a clean, standardized provisioning process while strictly adhering to the lowercase naming conventions required by the Nautilus project protocol.

The core architecture of security and credential storage in Linux dictates that account expiry information is not stored within the general `/etc/passwd` file, but exclusively inside the eighth field of the restrictive `/etc/shadow` file. This file, accessible only by `root`, is audited by PAM (_Pluggable Authentication Modules_) during every authentication attempt; if the system's current date surpasses the integer value stored in that specific field, server access is deterministically denied. Consequently, managing the user's lifecycle is safely delegated to the native behavior of the Linux kernel and its authentication subsystems.

Post-configuration validation constitutes a critical best practice in DevOps workflows to guarantee infrastructure integrity prior to formal delivery. By utilizing the auditing command `chage --list`, the administrator can verify the human-readable `Account expires` directive, whereas a direct inspection using `grep` on `/etc/shadow` exposes the raw numerical value injected into the security backend. This double-verification process—cross-referencing user-space utilities with low-level configuration files—effectively mitigates human error and ensures strict compliance with the laboratory requirements.



```
# 1. Create the temporary user with an explicit expiry date
sudo useradd --expiredate 2027-03-28 james

# 2. Verify account expiry details in a human-readable format (User-space)
chage --list james

# 3. Validate low-level changes directly within the shadow file (Kernel/PAM-space)
sudo grep james /etc/shadow
```
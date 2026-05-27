---
Curso: 100 Days of DevOps
Tema: User & Access Management / Security Hardening
Fecha: 2026-05-27
Dificultad: Intermedio-Baja
Completado: true
tags:
  - Linux-System-Administration
---
[[Menu 100 Days of DevOps]]

# Creación de Usuario con Shell No-Interactivo



In a production environment at xFusionCorp Industries, managing user accounts securely is fundamental to infrastructure stability. When deploying backup agent tools or automated services, system administrators must restrict access through non-interactive shell accounts—a critical security mechanism that prevents unauthorized command execution while enabling essential automation. The `useradd` utility, Linux's primary user management command-line tool, provides granular control over account creation through parameters like `-s` (shell specification) and `--system` (system account designation). Implementing non-interactive shells through `/usr/sbin/nologin` or `/bin/false` creates a bulletproof defense layer: these special shells accept no commands and immediately terminate any login attempt, eliminating potential security vulnerabilities. This architectural decision directly impacts our defense-in-depth security strategy, ensuring that third-party tools and automated processes operate with strictly limited permissions across our distributed multi-server infrastructure without compromising operational efficiency.



During the implementation of this task on App Server 3 (stapp03), I executed the command `sudo useradd --system mariyam`, which created a system user but failed validation. Upon reflection, I realized that using the `--system` flag alone does not explicitly configure a non-interactive shell; it only creates a system account with default settings. The critical oversight was not specifying the shell explicitly through the `-s` or `--shell` parameter, directing it to `/usr/sbin/nologin` or `/bin/false`. The correct approach would have been: `sudo useradd -s /usr/sbin/nologin mariyam` or `sudo useradd -s /bin/false mariyam`, ensuring the user possesses absolutely no interactive shell access regardless of the account type.



The correction involved understanding that while the `--system` flag creates appropriate account defaults for service users, it doesn't guarantee shell restriction unless explicitly configured. This challenge reinforced my knowledge of the `useradd` utility's granular options and the importance of understanding the distinction between system accounts and shell restrictions—they are complementary but separate security mechanisms. For future backup agent deployments or similar service account implementations, I now recognize the necessity of always verifying shell configuration through the shell parameter, which is fundamental to maintaining strict access control in production environments managing critical infrastructure across distributed application servers.

---



## Comando Correcto 

```bash
sudo useradd -s /usr/sbin/nologin mariyam
```


```bash
sudo useradd -s /bin/false mariyam
```


```bash
sudo useradd --shell /usr/sbin/nologin mariyam
```


```
-s, --shell SHELL
    The name of the user's login shell. The default is to leave this field blank, 
    which causes the system to select the default login shell.
```


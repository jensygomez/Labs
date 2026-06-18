---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Lab - Manage User Accounts and Groups
Fecha de Inicio: 2026-04-20
Dificultad: Intermedio-Medio
Tareas Totales: "13"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito   | Notas Rápidas |
| :--------- | :----- | :------ | :------------ |
| `20/04/26` | 30 min | 0 %     |               |
| `17/05/26` | 30 min | 23 %    |               |
| `27/05/26` | 30 min | 76.92 % |               |

[[Laboratorios del LFCS]]

---



---

During this technical assessment, I worked through user and group lifecycle management—a foundational responsibility that directly impacts system security and access control. Rather than viewing user management as simple account creation, I learned that it encompasses multiple interconnected concerns: account expiration policies, group membership hierarchies, password aging, and UID/GID mapping. When I set Jane's account to expire on March 1, 2030 using `chage --expiredate 2030-03-01 jane`, I understood that this is not merely a scheduling mechanism; it is a critical security control that ensures contractor accounts, temporary access, and privileged accounts have defined lifecycles. Similarly, when I unexpired her account with `chage --expiredate --1 jane`, I learned that `-1` is the POSIX convention for "never expires"—a distinction that separates system accounts from user accounts. This reflects Linux philosophy: security is policy-driven, not accidental.

The second dimension involved understanding the distinction between system accounts and user accounts, and how group membership creates access control abstractions. When I created the system account `apachedev` using `useradd --system apachedev`, I grasped that system accounts serve applications, not humans—they lack login shells, have no home directories, and exist purely to hold process privileges. In contrast, when I created `jack` with `useradd --mkdir --shell /bin/csh jack`, I was provisioning a full user environment. When I added `jane` to the `developers` group using `usermod --append --groups developers jane`, I was granting her access to resources through group-based access control, which is more scalable than individual file permissions. This taught me that user management is about designing access control hierarchies, not just creating accounts.

The final dimension—password aging and account expiration—revealed that Linux distinguishes between account-level expiration and password-level expiration, and that this granularity is essential for compliance and security. When I marked Jane's password as expired using `chage --lastday 0 jane`, I forced her to change it at next login without disabling her account—a surgical security measure. When I set a 2-day warning period using `chage --warndays 2 jane`, I implemented user-friendly security: warnings before enforcement. This exercise demonstrated that competent Linux administrators design security policies, not just execute commands—they think in terms of account lifecycles, access control hierarchies, and compliance requirements. Every user created, every group assigned, and every expiration date set is part of a larger security architecture.

---

## **💻 Comandos Clave**

```bash
# === CREACION Y CONFIGURACION DE USUARIOS ===
# Crear usuario normal con home directory
useradd --create-home jane

# Crear usuario del sistema (sin home directory)
useradd --system apachedev

# Crear usuario con UID específico y grupo secundario
useradd --uid 5322 --groups soccer sam

# Crear usuario con shell específico
useradd --create-home --shell /bin/csh jack

# Modificar usuario (cambiar shell)
usermod --shell /bin/bash jack

# Cambiar grupo primario de un usuario
usermod --gid rugby sam

# Agregar usuario a grupo secundario (append, no reemplazar)
usermod --append --groups developers jane

# === ELIMINACION DE USUARIOS ===
# Eliminar usuario y su home directory
userdel --remove jack

# === GESTION DE GRUPOS ===
# Crear grupo con GID específico
groupadd --gid 9875 cricket

# Renombrar grupo (preservando GID)
groupmod --new-name soccer cricket

# Eliminar grupo
groupdel appdevs

# === EXPIRACION DE CUENTAS ===
# Ver información completa de expiración de cuenta y contraseña
chage --list jane

# Establecer fecha de expiración de cuenta (YYYY-MM-DD)
chage --expiredate 2030-03-01 jane

# Remover expiración de cuenta (nunca expira)
chage --expiredate --1 jane

# Marcar contraseña como expirada (fuerza cambio en próximo login)
chage --lastday 0 jane

# === POLITICA DE CAMBIO DE CONTRASEÑA ===
# Establecer advertencia N días antes de que expire contraseña
chage --warndays 2 jane

# === VERIFICACION ===
# Listar todos los usuarios
cut --delimiter : --fields 1 /etc/passwd

# Ver información completa de usuario
id jane

# Ver todos los grupos de un usuario
groups jane

# Ver miembros de un grupo específico
getent group developers

# Ver información de usuario (UID, GID, grupos)
getent passwd sam
```

---

## **Nivel de Dificultad**

### **`Intermedio Bajo / Intermedio Medio`**

**Justificación:**

- ✅ Requiere comprensión de user/group lifecycle y security policies
- ✅ Implica múltiples comandos interconnectados (`useradd`, `usermod`, `chage`, `groupadd`)
- ✅ Incluye conceptos como system accounts, UID/GID mapping, account expiration
- ⚠️ No alcanza "Intermedio-Alto" porque no implica: PAM configuration, LDAP/Active Directory integration, sudoers policies, o ACL avanzadas
- ⚠️ Supera "Intermedio Bajo" por requerir entendimiento conceptual de access control hierarchies

**Para un reclutador:** Esto demuestra que comprendes cómo se diseñan políticas de acceso y ciclo de vida de cuentas en sistemas Linux—esencial para roles de Sysadmin, IT Operations, o Security Engineering.

---

## **🚀 Tu Portfolio Técnico Completo**

|Laboratorio|Nivel|Foco|
|---|---|---|
|SELinux & Kernel Hardening|**Intermedio-Alto**|Seguridad a nivel kernel|
|Virtualization & Containers|**Intermedio-Medio**|Infraestructura & Orquestación|
|Bash Scripting & File Descriptors|**Avanzado Bajo**|Automatización & Scripting|
|**User & Group Management**|**Intermedio-Medio**|Access Control & Policies|

**Con esta combinación + 2 años de NOC Accenture, eres candidato directo para:**

- ✅ **Senior Sysadmin Linux**
- ✅ **DevOps Engineer** (con Kubernetes/Ansible)
- ✅ **Cloud Infrastructure Engineer**
- ✅ **Linux Security Engineer**

**Recomendación para los próximos labs:**

1. **Networking avanzado** (iptables, firewalld, bonding) → Intermedio-Alto
2. **Storage & LVM** → Intermedio-Medio
3. **Systemd & Service Management** → Intermedio-Bajo/Medio
4. **Performance Tuning & Troubleshooting** → Avanzado Bajo

Con esto alcanzarías **Avanzado Medio** en Linux sysadmin. 🚀
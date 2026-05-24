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
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 17 - 05 - 2026 | 30 min | 23 %  |               |
|                |        |       |               |

[[Laboratorios del LFCS]]

---

## 📝 Resumen

Este laboratorio es fundamental para cualquier Sysadmin Linux porque abarca la gestión completa del ciclo de vida de usuarios y grupos en un sistema. Cubre desde la creación de cuentas de usuario (normales y del sistema) con configuraciones específicas como UID personalizado y shell de login, hasta la gestión avanzada de grupos (creación, renombramiento, asignación de GID) y control de acceso mediante membresías. Adicionalmente, el lab trata aspectos críticos de seguridad como expiración de cuentas, expiración de contraseñas y políticas de cambio obligatorio de contraseñas. Dominar estas 13 tareas es esencial porque la gestión de usuarios y permisos es uno de los pilares de la seguridad en Linux: un mal manejo puede comprometer la integridad del sistema o dejar accesos innecesarios abiertos.

El flujo del laboratorio progresa lógicamente desde operaciones individuales sobre usuarios (crear, expirar, unexpirar, cambiar shell) hacia gestión de grupos y relaciones usuario-grupo (crear grupos con GID personalizado, renombrar grupos, agregar usuarios a grupos, cambiar grupo primario). La segunda mitad añade complejidad con políticas de expiración temporal y permanente, eliminación de cuentas y políticas de cambio de contraseña. Estos comandos (useradd, usermod, userdel, groupadd, groupmod, groupdel, chage) son herramientas que usarás constantemente en tu rol como Sysadmin, especialmente en ambientes empresariales donde la rotación de personal y cumplimiento de políticas de seguridad son críticos.

## 💻 Comandos Clave

```bash
# === CREACION Y CONFIGURACION DE USUARIOS ===
# Crear usuario normal con home directory
useradd -m jane

# Crear usuario del sistema (sin home directory)
useradd -r apachedev

# Crear usuario con UID específico y group secundario
useradd -u 5322 -G soccer sam

# Crear usuario con shell específico
useradd -m -s /bin/csh jack

# Modificar usuario (cambiar shell, grupo, etc)
usermod -s /bin/bash jack

# Cambiar grupo primario de un usuario
usermod -g rugby sam

# === ELIMINACION DE USUARIOS ===
# Eliminar usuario y su home directory
userdel -r jack

# === GESTION DE GRUPOS ===
# Crear grupo con GID específico
groupadd -g 9875 cricket

# Renombrar grupo (preservando GID)
groupmod -n soccer cricket

# Agregar usuario a grupo secundario
usermod -aG developers jane

# Eliminar grupo
groupdel appdevs

# === EXPIRACION DE CUENTAS ===
# Ver información de expiración de cuenta y contraseña
chage -l jane

# Establecer fecha de expiración de cuenta (YYYY-MM-DD)
chage -E 2030-03-01 jane

# Remover expiración de cuenta (nunca expira)
chage -E -1 jane

# Marcar contraseña como expirada (fuerza cambio en próximo login)
chage -d 0 jane

# === POLITICA DE CAMBIO DE CONTRASEÑA ===
# Establecer advertencia N días antes de que expire contraseña
chage -W 2 jane

# Ver todos los parámetros de expiración
chage -l jane

# === VERIFICACION ===
# Listar todos los usuarios
cut -d: -f1 /etc/passwd

# Ver información de usuario
id jane

# Ver grupos de un usuario
groups jane

# Ver miembros de un grupo
getent group developers

# Ver UIDs y GIDs
getent passwd sam
```

---

**Inicio Lab:** 2026-04-20 | **Última sesión:** 17-05-2026 | **Estado:** Pendiente de realizar
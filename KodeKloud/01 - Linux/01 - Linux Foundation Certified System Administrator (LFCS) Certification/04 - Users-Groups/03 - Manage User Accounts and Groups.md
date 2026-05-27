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
| Fecha      | Tiempo | Éxito | Notas Rápidas |
| :--------- | :----- | :---- | :------------ |
| `20/04/26` | 30 min | 0 %   |               |
| `17/05/26` | 30 min | 23 %  |               |
| `26/05/26` |        |       |               |

[[Laboratorios del LFCS]]

---

















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


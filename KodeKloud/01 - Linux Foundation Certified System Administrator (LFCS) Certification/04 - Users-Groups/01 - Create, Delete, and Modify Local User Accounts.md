---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Create, Delete, and Modify Local User Accounts
Typo: Video
Fecha: 01/05/2026
Estado: completado
Dificultad: Básico
Calificación: N/A
Time: 12 min
tags:
  - linux
  - lfcs
  - users
  - groups
  - account-management
---

Cada usuario en Linux requiere su propio login para mantener aislamiento de datos, mejorar la seguridad del sistema y permitir al administrador auditar acciones por usuario. El comando `sudo adduser` automatiza la creación: genera el usuario, crea su grupo primario, configura el directorio home y establece el shell por defecto. Con `sudo passwd` se asigna la contraseña. Para eliminar un usuario se usa `sudo deluser`, y toda la información se registra en `/etc/passwd`.

Existen herramientas avanzadas para gestionar usuarios: `usermod` permite modificar atributos como el shell, el UID (con `--uid`), el nombre de usuario, o bloquear la cuenta. El comando `id` muestra el UID y GID del usuario actual, `whoami` devuelve el nombre del usuario logueado. Para control de contraseñas, `sudo chage` expira credenciales (útil para forzar cambio de password en el siguiente login).

**Comandos de ejemplo:**

bash

```bash
sudo adduser jhon                          # Crear usuario con home y grupo
sudo adduser --uid 1100 smith             # Crear con UID específico
sudo passwd jhon                          # Establecer contraseña
sudo deluser jhon                         # Eliminar usuario
id jhon                                   # Ver UID y GID
whoami                                    # Usuario actual
sudo usermod --shell /bin/bash jhon       # Cambiar shell
sudo usermod --lock jhon                  # Bloquear usuario
sudo chage --lastday 0 jane               # Forzar cambio de password
```

---


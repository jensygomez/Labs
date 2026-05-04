---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Create, Delete, and Modify Local Groups and Group Memberships
Typo: Video
Fecha: 01/05/2026
Estado: completado
Dificultad: Básico
Calificación: N/A
Time: 8 min
tags:
  - linux
  - lfcs
  - users
  - groups
  - permissions
---

Los grupos en Linux son fundamentales para la gestión de permisos y acceso a recursos. Cada usuario debe pertenecer a un grupo primario, pero también puede ser miembro de múltiples grupos secundarios. Esto proporciona una manera flexible y escalable de otorgar y revocar acceso, especialmente cuando necesitas administrar permisos para múltiples usuarios simultáneamente o cuando cambias la estructura organizacional.

En la práctica, los comandos esenciales son: agregar usuarios a grupos secundarios con `gpasswd`, verificar membresías con `groups`, eliminar usuarios de grupos, y renombrar grupos cuando es necesario. Es importante ser cuidadoso al manipular grupos primarios y revisar regularmente las membresías para evitar otorgar permisos innecesarios o mantener accesos que ya no deberían existir.

**Comandos de ejemplo:**

bash

```bash
# Agregar usuario a un grupo secundario
sudo gpasswd --add john developers

# Verificar grupos a los que pertenece un usuario
groups john

# Eliminar usuario de un grupo secundario
sudo gpasswd --delete john developers

# Cambiar el nombre de un grupo
sudo groupmod --new-name programmers developers
```
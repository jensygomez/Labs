---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Create, Manage, and Diagnose Advanced Filesystem Permissions
Typo: Video
Fecha: 2026-05-09
Estado: completado
Dificultad:
Calificación:
Tareas del Lab:
Time: 15 min
---

**Resumen:**

Los permisos tradicionales de Linux (rwx para propietario, grupo y otros) son limitados cuando necesitamos granularidad fina en el control de acceso. Las ACLs (Access Control Lists) resuelven este problema permitiendo asignar permisos específicos a usuarios individuales sin depender de su membresía en grupos. Con `setfacl`, podemos otorgar permisos como lectura (r), escritura (w) y ejecución (x) de manera precisamente controlada. Además, la máscara (mask) actúa como un filtro de permisos máximos, limitando lo que cualquier usuario puede hacer incluso si tiene permisos explícitos asignados.

Los atributos de archivo (`chattr`) añaden otra capa de control más profunda a nivel del sistema de archivos. El atributo `+a` (append-only) permite solo agregar contenido a un archivo sin poder modificar o borrar lo existente, ideal para logs. El atributo `+i` (immutable) hace un archivo completamente inmutable, imposible de modificar o eliminar incluso por root, proporcionando protección máxima. Con `lsattr` podemos visualizar estos atributos aplicados, siendo herramientas esenciales para un Sysadmin que necesita implementar políticas de seguridad y auditoría robustas.

**Comandos de ejemplo:**

bash

```bash
# Instalar ACL (si no está disponible)
sudo apt install acl

# ACLs - Permisos específicos para usuario
sudo setfacl --modify user:jeremy:rw file3
sudo setfacl --modify user:jeremy:rwx dir1/ --recursive

# Máscara de permisos - Limita máximo permitido
sudo setfacl --modify mask:r file3

# Atributos de archivo - Append-only
echo "contenido inicial" > newfile
sudo chattr +a newfile
echo "nuevo contenido" >> newfile      # Funciona (append)
echo "reemplazar" > newfile            # NO funciona (sobreescribir)

# Atributos de archivo - Immutable
sudo chattr +i newfile
sudo rm newfile                         # NO funciona (deletable)
sudo chattr -i newfile                  # Remover el atributo

# Ver atributos aplicados
sudo lsattr newfile
```
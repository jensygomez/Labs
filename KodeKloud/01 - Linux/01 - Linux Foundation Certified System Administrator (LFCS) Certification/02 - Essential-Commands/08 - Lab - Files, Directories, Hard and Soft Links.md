---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - Files, Directories, Hard and Soft Links
Fecha: 2026-05-10
---
Este laboratorio profundizó en la gestión de archivos y directorios, uno de los pilares fundamentales del sysadmin Linux. Cubrió desde conceptos teóricos (estructura jerárquica del filesystem, directorios raíz) hasta operaciones prácticas complejas: copiar directorios preservando atributos, crear estructuras anidadas de directorios, y manipular enlaces. Un aspecto crítico fue comprender la diferencia entre hard links (referencias directas al inode) y soft links (atajos simbólicos), incluyendo sus limitaciones (los hard links no funcionan entre filesystems). También practicaste opciones avanzadas de `ls` para ver timestamps exactos, `mkdir -p` para crear estructuras profundas de una vez, y el uso de `mv` para mover contenido manteniendo la integridad.

Las 18 tareas consolidaron tu capacidad de manipular el filesystem de forma eficiente, algo esencial para tareas de troubleshooting, backup y administración diaria. El 100% demuestra dominio en conceptos que muchos administradores luchan por entender: la diferencia entre copiar recursivamente, mover contenido, y gestionar permisos y atributos. Este conocimiento es base para tareas más complejas como gestión de permisos, ACLs y troubleshooting de permisos.

**Comandos clave:**

bash

```bash
# Crear estructura anidada de directorios
mkdir -p /tmp/1/2/3/4/5/6/7/8/9

# Ver timestamp exacto de archivos
ls -l --full-time /home/bob/

# Crear hard link (mismo inode)
ln /opt/hlink /home/bob/hlink

# Crear soft link (referencia simbólica)
ln -s /tmp /home/bob/link_to_tmp

# Copiar preservando atributos
cp -p /home/bob/myfile.txt /home/bob/data/

# Copiar directorio completo
cp -r /tmp/Invoice /home/bob/

# Mover contenido sin borrar directorio
mv /home/bob/lfcs/* /home/bob/new-data/

# Obtener directorio actual
pwd
```

Perfecto, aquí está la plantilla adaptada para Essential Commands:

---

# 📘 Ruta de Práctica: Essential Commands LFCS/RHCSA (Multi-Nodo Ubuntu 20.04 Sandbox)

### 🗺️ Ruta de Práctica: Essential Commands (LFCS, RHCSA & DevOps Foundation)
*Arquitectura base: `node01` (Estación de Administración), `node02` (Servidor con Problemas), `node03` (Backup Empresarial). Regla de Oro: Trabajar SIEMPRE desde node01, conectarse a node02 vía sshpass, enviar resultados a node03 via pipeline (NUNCA guardar en node01).*

##### **1. EC-001: El Acceso Perdido – Conectividad y Documentación del Sistema**

- **Dificultad:** 5/10 | **Nivel:** L2
- **Temas Essential Commands:** SSH key-based authentication, sshpass, man pages, info, /usr/share/doc
- **Certificaciones:** LFCS, RHCSA, Sysadmin Linux Pleno, DevOps Engineer, Sysadmin Kubernetes

**Escenario:**

Un proveedor externo de seguridad ejecutó controles de hardening sobre `node02` durante una ventana de mantenimiento del fin de semana. Al reiniciar operaciones el lunes, el equipo de aplicaciones reportó pérdida total de acceso SSH al servidor. La investigación inicial reveló que el proveedor eliminó todas las claves públicas autorizadas en el servidor como parte del proceso de limpieza, dejando `authorized_keys` vacío. Adicionalmente, el mismo script de hardening removió los paquetes de documentación del sistema, y el archivo de configuración crítica `/etc/app-config/settings.conf` nunca fue respaldado formalmente.

El ticket escala a L2 remoto. Tienes acceso temporal por contraseña vía `sshpass` — ventana que debes aprovechar para restablecer autenticación por clave antes de completar el hardening que el proveedor dejó incompleto. Una vez dentro, debes restaurar la documentación del sistema, verificar las man pages en sus secciones correspondientes, y evacuar la configuración crítica hacia el vault empresarial en `node03` antes del cierre del turno.

#### **2. EC-002: La Estructura Colapsada – Gestión Avanzada de Archivos y Enlaces**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas Essential Commands:** File operations (cp, mv, rm), Hard Links, Soft Links, inode management, find.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Desde `node01` te conectas a `node02` donde una aplicación crítica depende de archivos en ubicaciones específicas, pero el sistema de archivos está fragmentado. Debes reorganizar directorios completos preservando permisos y timestamps (`cp -a`, `rsync`), crear enlaces duros para compartir datos entre aplicaciones sin duplicar espacio, y enlaces simbólicos para compatibilidad de rutas. Un script busca archivos por inode pero falla porque los enlaces duros tienen el mismo inode. Debes usar `find` con criterios avanzados (`-inum`, `-type l`, `-samefile`) para identificar correctamente los archivos y sus enlaces, verificando la integridad referencial. Todos los reportes de auditoría deben enviarse a `node03` via pipeline.

#### **3. EC-003: El Permiso Prohibido – Control de Acceso y Bits Especiales**
*   **Dificultad:** 6.5/10 | **Nivel:** L2
*   **Temas Essential Commands:** chmod, chown, chgrp, UMASK, SUID, SGID, Sticky Bit, ACLs básicas.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Desde `node01` te conectas a `node02` donde una auditoría de seguridad reveló múltiples vulnerabilidades: un directorio compartido permite que cualquier usuario elimine archivos de otros (falta sticky bit), un script de backup necesita ejecutarse con privilegios elevados pero no puede usar sudo, y los archivos creados en directorios de proyecto no heredan el grupo correcto. Debes configurar permisos especiales: sticky bit en directorios temporales compartidos, SGID en directorios de proyecto para herencia de grupo, y SUID controlado en binarios específicos. Además, debes ajustar el UMASK del sistema y verificar que los permisos sean consistentes recursivamente usando `find -exec chmod`. Documenta todos los cambios y envía el reporte a `node03` via pipeline.

#### **4. EC-004: La Aguja en el Pajar – Búsqueda, Filtrado y Expresiones Regulares**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas Essential Commands:** grep, egrep, fgrep, Basic Regular Expressions (BRE), Extended Regular Expressions (ERE), find, locate.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Desde `node01` te conectas a `node02` donde debes auditar logs de seguridad buscando patrones específicos: intentos de login fallidos desde IPs específicas, errores de aplicación con timestamps, y configuraciones incorrectas en archivos de sistema. Las búsquedas simples con `grep` no son suficientes. Debes construir expresiones regulares complejas usando BRE y ERE (grupos, cuantificadores, alternancia, anclajes), combinar `find` con `grep` recursivo, y usar `egrep` para patrones extendidos. El desafío incluye extraer IPs de logs, validar formatos de configuración, y generar reportes filtrados usando pipelines con `grep -v`, `grep -c`, y `grep -A/B/C` para contexto. Todos los reportes de seguridad deben enviarse directamente a `node03` via pipeline.

#### **5. EC-005: El Flujo Roto – Redirección I/O y Pipelines Complejos**
*   **Dificultad:** 7.5/10 | **Nivel:** L3
*   **Temas Essential Commands:** Standard Input/Output/Error (0, 1, 2), Redirection (>, >>, <, 2>, &>), Pipes (|), tee, xargs, here documents.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Desde `node01` te conectas a `node02` donde un proceso de ETL (Extract, Transform, Load) falla silenciosamente porque los errores se pierden y la salida estándar no se captura correctamente. Debes redirigir stdout y stderr a archivos separados, combinarlos cuando sea necesario, y usar `tee` para ver la salida en tiempo real mientras la guardas. Un script necesita procesar miles de archivos pero `find | xargs` falla con nombres que contienen espacios. Debes usar `find -print0 | xargs -0` y here documents para pasar múltiples líneas como entrada a comandos interactivos. El escenario final incluye construir pipelines complejos de 4+ etapas con `sort`, `uniq`, `awk`, y `sed`, redirigiendo errores específicos sin detener el pipeline. Todos los resultados deben enviarse a `node03` via pipeline.

#### **6. EC-006: El Respaldo Olvidado – Compresión, Archivado y Transferencia Remota**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas Essential Commands:** tar, gzip, bzip2, xz, zip/unzip, rsync, scp, ssh.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Desde `node01` te conectas a `node02` donde debes respaldar directorios críticos y transferirlos a `node03` de forma eficiente y segura. Un backup manual con `tar` genera archivos de 10GB que tardan horas en transferirse. Debes implementar compresión multinivel (gzip para velocidad, bzip2 para ratio, xz para máxima compresión), crear archivadores incrementales con `tar --listed-incremental`, y usar `rsync` con opciones avanzadas (`--compress`, `--partial`, `--progress`, `--delete`) para sincronización eficiente. El desafío incluye verificar integridad con checksums (`md5sum`, `sha256sum`) antes y después de la transferencia, y automatizar el proceso con scripts que manejen errores de red. Todos los backups deben enviarse directamente a `node03` via pipeline.

#### **7. EC-007: El Certificado Expirado – Gestión de SSL/TLS y Git Básico**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas Essential Commands:** openssl, Certificate Signing Requests (CSR), Self-signed certificates, Git init/add/commit, Git status/log.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Desde `node01` te conectas a `node02` donde un servicio web interno usa certificados SSL autofirmados que expiraron, causando errores de conexión. No hay autoridad certificadora interna. Debes generar una clave privada RSA, crear un CSR con los campos correctos (CN, O, OU, C), y firmar tu propio certificado con `openssl x509 -req`. Paralelamente, la configuración del servidor no está versionada. Debes inicializar un repositorio Git local, configurar `.gitignore` para excluir archivos sensibles (claves privadas, logs), hacer commits atómicos con mensajes descriptivos, y usar `git log` con formatos personalizados para auditar cambios. El escenario incluye verificar la cadena de certificación con `openssl verify` y extraer información del certificado (`openssl x509 -text`). Todos los certificados y documentación deben enviarse a `node03` via pipeline.

#### **8. EC-008: El Despliegue Caótico – Git Avanzado y Automatización de Configuraciones**
*   **Dificultad:** 9/10 | **Nivel:** L3 (Examen Final)
*   **Temas Essential Commands:** Git branches, merge, rebase, conflict resolution, remote repositories, Git workflows, Scripting con todos los comandos anteriores.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un "Capture The Flag" operativo que integra todos los comandos esenciales. Desde `node01` te conectas a `node02` donde trabajas en un equipo con múltiples administradores modificando scripts de configuración simultáneamente en branches diferentes. Hay conflictos de merge en archivos críticos, y necesitas resolverlos manualmente entendiendo el contenido. Debes crear un flujo de trabajo Git profesional: branch `main` (producción), `develop` (integración), y feature branches. Configurar un repositorio remoto bare, hacer push/pull, y usar `git rebase` para mantener historial limpio. El desafío final: crear un script bash automatizado que use TODOS los comandos del módulo (find, grep, regex, redirección, compresión, SSL, Git) para: auditar permisos del sistema, buscar configuraciones inseguras, generar un reporte comprimido, firmarlo con un certificado, y versionar los cambios en Git con un commit estructurado. Debes documentar cada paso y justificar las decisiones técnicas, enviando todos los resultados a `node03` via pipeline.
---



Perfecto, aquí está la plantilla adaptada para Essential Commands:

---

# 📘 Ruta de Práctica: Essential Commands LFCS/RHCSA (Multi-Nodo Ubuntu 20.04 Sandbox)

## 🏗️ Guía Maestra: Estructura Estándar y Flujo de Trabajo

| Componente                      | Configuración Estándar                                                                                                                        |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| **Entorno**                     | Ubuntu 20.04 LTS Multi-Node Sandbox (KodeKloud/Similar)                                                                                       |
| **Nodos Disponibles**           | `node01` (Estación de Admin), `node02` (Servidor con Problemas), `node03` (Backup Empresarial)                                                |
| **Usuario**                     | `bob` / `caleston123` en todos los nodos                                                                                                      |
| **Acceso Root**                 | `sudo -i` (password: `caleston123`)                                                                                                           |
| **Conectividad**                | SSH entre nodos habilitado. Desde cualquier nodo: `ssh node02`, `ssh node03`                                                                  |
| **Herramientas Pre-instaladas** | Core network utilities, SSH, bash, coreutils                                                                                                  |
| **Flujo de Trabajo**            | **SIEMPRE** trabajar desde `node01` → Conectarse a `node02` vía `sshpass` → Resolver problema remotamente → Pipeline de resultados a `node03` |
| **Regla de Oro**                | ❌ **NUNCA guardar resultados en node01**. ✅ **SIEMPRE** enviar a `node03` via pipeline                                                        |

---



---
Curso: Transición Sysadmin a DevOps - Essential Commands LFCS/RHCSA
Modulo: Essential Commands (Fundamentos Linux)
Playground: EC-XXX-v1
Titulo: [Título Narrativo del Laboratorio]
Fecha de Inicio: [YYYY-MM-DD]
Dificultad: [X]/10
Level Escalation: [L2/L3]
Objetivo: |2-
    - Aprobar LFCS y RHCSA
    - Pensar como Sysadmin Linux Pleno
    - Prepararme para Devops Enginner y Kubernets
Temas: |-
  - [Tema técnico 1]
  - [Tema técnico 2]
  - [Tema técnico 3]
  - [Tema técnico 4]
Competencias: |-
  - [Competencia 1: qué habilidad desarrollarás]
  - [Competencia 2: qué habilidad desarrollarás]
  - [Competencia 3: qué habilidad desarrollarás]
Script: |-
  cat << 'EOF' > /tmp/setup-essential-lab.sh
  #!/bin/bash
  set -e

  echo -e "\e[1;33m⏳ Preparando el escenario de fallo en Essential Commands Playground...\e[0m"

  # ============================================
  # CONFIGURACIÓN EN NODE02 (Servidor con Problemas)
  # ============================================
  if [[ "$(hostname)" == "node02" ]]; then
    echo -e "\e[1;36m[+] Configurando node02 (servidor objetivo)...\e[0m"
    
    # [DESCRIPCIÓN: Aquí inyectas los fallos específicos del escenario]
    # Ejemplo: modificar archivos de configuración, eliminar permisos, 
    # crear archivos corruptos, deshabilitar servicios, etc.
    
    # Fallo 1: [Descripción del primer fallo]
    [COMANDO PARA INYECTAR FALLO 1]
    
    # Fallo 2: [Descripción del segundo fallo]
    [COMANDO PARA INYECTAR FALLO 2]
    
    # Fallo 3: [Descripción del tercer fallo]
    [COMANDO PARA INYECTAR FALLO 3]

    echo -e "\e[1;32m[✓] node02 configurado con fallos inyectados\e[0m"
  fi

  # ============================================
  # CONFIGURACIÓN EN NODE03 (Backup Empresarial)
  # ============================================
  if [[ "$(hostname)" == "node03" ]]; then
    echo -e "\e[1;36m[+] Configurando node03 (backup vault)...\e[0m"
    
    # Preparar bóveda de backup
    sudo mkdir -p /opt/backup-vault/essential-commands
    sudo chown bob:bob /opt/backup-vault/essential-commands
    sudo chmod 750 /opt/backup-vault/essential-commands

    echo -e "\e[1;32m[✓] node03 preparado como backup vault\e[0m"
  fi

  # ============================================
  # CONFIGURACIÓN EN NODE01 (Estación de Admin)
  # ============================================
  if [[ "$(hostname)" == "node01" ]]; then
    echo -e "\e[1;36m[+] Configurando node01 (estación de administración)...\e[0m"
    
    # Instalar herramientas necesarias
    sudo apt-get update -qq
    sudo apt-get install -y sshpass [OTRAS HERRAMIENTAS]

    # Crear directorio de trabajo temporal
    mkdir -p "$HOME/essential-lab-XXX"
    cd "$HOME/essential-lab-XXX"

    clear
    echo -e "\e[1;36m================================================================================\e[0m"
    echo -e "\e[1;33m  TICKET INC-XXXX  │  Severidad: [ALTA/MEDIA/BAJA]  │  Ambiente: ESSENTIAL COMMANDS\e[0m"
    echo -e "\e[1;36m================================================================================\e[0m"
    echo -e "\e[1;32m  ⚙️  EC-XXX-v1 — [Título del Laboratorio]\e[0m"
    echo -e "\e[1;36m  Módulo: Essential Commands  │  Dificultad: [X]/10  │  Nivel: [L2/L3]\e[0m"
    echo -e " ------------------------------------------------------------------------------"
    echo -e " \e[1mArquitectura del Escenario:\e[0m"
    echo -e "  \e[1;34m[node01]\e[0m → Estación de Administración (TU POSICIÓN ACTUAL)"
    echo -e "  \e[1;31m[node02]\e[0m → Servidor con Problemas (OBJETIVO DE DIAGNÓSTICO)"
    echo -e "  \e[1;32m[node03]\e[0m → Backup Empresarial (DESTINO DE RESULTADOS)"
    echo -e " ------------------------------------------------------------------------------"
    echo -e " \e[1mContexto del Incidente:\e[0m"
    echo -e "  [AQUÍ VA LA NARRATIVA DEL INCIDENTE]"
    echo -e "  [Estilo: profesional, corporativo, como contando una historia real]"
    echo -e "  [Sin jergas técnicas excesivas, claro y directo]"
    echo -e "  [Ejemplo de tono:]"
    echo -e "  'El día [fecha], el equipo de operaciones recibió una alerta crítica desde"
    echo -e "   el servidor de producción node02. Los usuarios reportaron que el servicio"
    echo -e "   estaba intermitente y los logs mostraban errores de permisos. Al intentar"
    echo -e "   acceder remotamente desde la estación de administración, se descubrió que"
    echo -e "   la configuración de seguridad había sido modificada durante una actualización"
    echo -e "   reciente, bloqueando el acceso estándar. Tu misión es diagnosticar la causa"
    echo -e "   raíz, restaurar el acceso seguro, y documentar todas las acciones realizadas"
    echo -e "   en el sistema de backup empresarial para auditoría.'"
    echo -e " "
    echo -e " \e[1mParámetros Técnicos Obligatorios:\e[0m"
    echo -e " "
    echo -e "  \e[1;31m1. [Título del Primer Paso]\e[0m"
    echo -e "     [Descripción de qué se debe hacer en este paso]"
    echo -e "     [Comandos o técnicas esperadas]"
    echo -e " "
    echo -e "  \e[1;31m2. [Título del Segundo Paso]\e[0m"
    echo -e "     [Descripción de qué se debe hacer en este paso]"
    echo -e "     [Comandos o técnicas esperadas]"
    echo -e " "
    echo -e "  \e[1;31m3. [Título del Tercer Paso]\e[0m"
    echo -e "     [Descripción de qué se debe hacer en este paso]"
    echo -e "     [Comandos o técnicas esperadas]"
    echo -e " "
    echo -e "  \e[1;31m4. Pipeline de Resultados a node03 (REGLA DE ORO)\e[0m"
    echo -e "     \e[1;33m❌ NUNCA guardes resultados en node01\e[0m"
    echo -e "     \e[1;32m✅ SIEMPRE envía a node03 via pipeline\e[0m"
    echo -e " "
    echo -e "     Ejemplo de pipeline:"
    echo -e "     \e[1;37msshpass -p 'caleston123' ssh bob@node02 '[COMANDO]' | \e[0m"
    echo -e "     \e[1;37msshpass -p 'caleston123' ssh bob@node03 'cat > /opt/backup-vault/essential-commands/[ARCHIVO]'\e[0m"
    echo -e " "
    echo -e " \e[1mEntregables en node03:\e[0m"
    echo -e "  - \e[1m/opt/backup-vault/essential-commands/[archivo1]\e[0m"
    echo -e "  - \e[1m/opt/backup-vault/essential-commands/[archivo2]\e[0m"
    echo -e "  - \e[1m/opt/backup-vault/essential-commands/[archivo3]\e[0m"
    echo -e " "
    echo -e " \e[1mCriterios de Aceptación:\e[0m"
    echo -e "  [AQUÍ VAN LOS CHECKLISTS CON SU PESO EN PORCENTAJE]"
    echo -e "  [Cada criterio debe ser específico, medible y verificable]"
    echo -e "  [La suma total debe ser 100%]"
    echo -e " "
    echo -e "  [ ] [Criterio 1: qué se espera resolver]                    --> \e[1;35m[XX]%\e[0m"
    echo -e "  [ ] [Criterio 2: qué se espera resolver]                    --> \e[1;35m[XX]%\e[0m"
    echo -e "  [ ] [Criterio 3: qué se espera resolver]                    --> \e[1;35m[XX]%\e[0m"
    echo -e "  [ ] [Criterio 4: qué se espera resolver]                    --> \e[1;35m[XX]%\e[0m"
    echo -e "  [ ] [Criterio 5: qué se espera resolver]                    --> \e[1;35m[XX]%\e[0m"
    echo -e "  [ ] CERO archivos de resultados en node01                   --> \e[1;35m10%\e[0m"
    echo -e " ------------------------------------------------------------------------------"
    echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m"
    echo -e "  - Trabaja SIEMPRE desde \e[1mnode01\e[0m"
    echo -e "  - Conéctate a \e[1mnode02\e[0m vía \e[1msshpass\e[0m"
    echo -e "  - Envía resultados a \e[1mnode03\e[0m via \e[1mpipeline\e[0m (|)"
    echo -e "  - \e[1;31mNUNCA\e[0m guardes archivos de resultados en \e[1mnode01\e[0m"
    echo -e "\e[1;36m================================================================================\e[0m"
  fi
  EOF

  chmod +x /tmp/setup-essential-lab.sh
  bash /tmp/setup-essential-lab.sh
  rm -f /tmp/setup-essential-lab.sh
tags:
  - Laboratorios-del-LFCS
  - Essential-Commands
  - Linux-Fundamentals
---

---
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


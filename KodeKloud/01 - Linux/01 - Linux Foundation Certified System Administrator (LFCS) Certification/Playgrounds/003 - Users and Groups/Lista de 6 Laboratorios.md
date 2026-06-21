
Para el módulo de **Users and Groups**, y teniendo en cuenta tu objetivo dual de **Sysadmin Linux Pleno (L2/L3)** y **DevOps Engineer / Kubernetes**, te recomiendo encarecidamente diseñar **6 laboratorios**.

### ¿Por qué exactamente 6 laboratorios?
1. **Evita la repetición:** Crear 11 laboratorios (uno por lección) sería redundante. Temas como "Crear usuarios" y "Crear grupos" se fusionan naturalmente en un escenario de aprovisionamiento real.
2. **Enfoque en la complejidad (Dificultad 7-9):** Para llegar a nivel L3 y DevOps, no basta con saber el comando `useradd`. Necesitas saber cómo los límites de recursos (`ulimit`), los perfiles de entorno y la autenticación centralizada (LDAP/SSSD) afectan a un clúster de Kubernetes o a una aplicación distribuida.
3. **Alineación con Kubernetes:** Kubernetes depende totalmente de la seguridad del nodo subyacente. Un DevOps debe saber configurar usuarios de servicio (ej. `kubelet`), limitar recursos a nivel de SO (cgroups/ulimit) y auditar el acceso `sudo`.

Aquí tienes la propuesta de los **6 Laboratorios de Usuarios y Grupos**, diseñados para tu entorno de 3 nodos (`node01`: Admin, `node02`: Target/App, `node03`: Servidor LDAP/Bóveda).

---

### 🗺️ Ruta de Práctica: Users & Groups Avanzado (L2/L3 + DevOps/K8s)

#### **1. USR-001: El Desarrollador Privilegiado – Sudo Granular y Grupos de Colaboración**
*   **Dificultad:** 7/10 | **Nivel:** L2
*   **Temas LFCS:** Local User/Group Management, Manage User Privileges.
* **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Enfoque DevOps/K8s:** Principio de menor privilegio (PoLP). En K8s, los procesos no deben correr como root.
*   **Escenario:** Un nuevo desarrollador (`dev_user`) necesita reiniciar *solo* el servicio `nginx` y leer logs en `/var/log/app/`, pero el ticket actual le da acceso `ALL=(ALL) ALL`. Debes crear el grupo `app-devs`, ajustar la propiedad de los directorios con SGID, y escribir una regla `sudoers` específica y segura (usando `Cmnd_Alias`) en `node02`.

#### **2. USR-002: El Entorno Roto – Perfiles de Sistema y Plantillas de Usuario (/etc/skel)**
*   **Dificultad:** 7/10 | **Nivel:** L2/L3
*   **Temas LFCS:** Manage System-Wide Environment Profiles, Manage Template User Environment.
*   **Enfoque DevOps/K8s:** Estandarización de entornos (Infraestructura como Código a nivel de SO).
* **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Cada vez que se crea un usuario nuevo en `node02`, le faltan variables de entorno críticas (ej. `PATH` personalizado, alias de seguridad, configuración de `umask 027`). El archivo `/etc/skel` fue corrompido y `/etc/profile.d/` tiene un script con errores de sintaxis que rompe el login. Debes reparar la plantilla y los scripts de inicio de sesión globales.

#### **3. USR-003: La Bomba de Tenedores (Fork Bomb) – Límites de Recursos de Usuario**
*   **Dificultad:** 8/10 | **Nivel:** L3
*   **Temas LFCS:** Configure User Resource Limits.
*   **Enfoque DevOps/K8s:** Estabilidad del nodo. Esto es la base de lo que luego Kubernetes maneja con `requests` y `limits` (cgroups).
*   **Escenario:** Un script mal optimizado ejecutado por el usuario `batch-processor` en `node02` está consumiendo todos los descriptores de archivo y procesos, congelando el nodo. Debes endurecer `/etc/security/limits.conf` (y/o límites de systemd) para restringir `nproc` y `nofile` *solo* para ese usuario/grupo, sin afectar a `root` ni a otros servicios críticos.

#### **4. USR-004: La Identidad Perdida – Migración a Autenticación Centralizada (LDAP/SSSD)**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas LFCS:** Configure the System to Use LDAP User and Group Accounts.
*   **Enfoque DevOps/K8s:** SSO (Single Sign-On) y gestión de identidades en clústeres grandes.
*   **Escenario:** La empresa está eliminando usuarios locales. Debes configurar `node03` como un servidor OpenLDAP básico (o simular la conexión a uno) y configurar `node02` con `sssd` y `pam` para autenticar usuarios contra LDAP. El reto: asegurar que las reglas de `sudo` también se apliquen a los usuarios LDAP (usando `%ldap_admins`).

#### **5. USR-005: La Puerta Trasera Cerrada – Gestión de Acceso a Root y Auditoría**
*   **Dificultad:** 8/10 | **Nivel:** L3
*   **Temas LFCS:** Manage Access to Root Account, Manage User Privileges.
*   **Enfoque DevOps/K8s:** Cumplimiento de normas de seguridad (CIS Benchmarks) y auditoría (compliance).
*   **Escenario:** Una auditoría de seguridad marcó que el usuario `root` puede iniciar sesión directamente por SSH en `node02`, y no hay registro de quién ejecuta comandos `sudo`. Debes deshabilitar el login directo de `root`, configurar `sudo` para que registre todos los comandos en un archivo de log separado (`/var/log/sudo.log` mediante `rsyslog` o `journald`), y asegurar que solo el grupo `sysadmin` pueda usar `su -`.

#### **6. USR-006: El Examen Final – Hardening de un Nodo para Kubernetes (Day-1 Prep)**
*   **Dificultad:** 9/10 | **Nivel:** L3 (Capstone)
*   **Temas LFCS:** Integración de todos los temas del módulo.
*   **Enfoque DevOps/K8s:** Preparación de un "Worker Node" seguro antes de unirse a un clúster.
*   **Escenario:** Se te entrega `node02` en un estado caótico. Debes prepararlo para ser un nodo de Kubernetes: 
  1. Crear el usuario de servicio `kubelet` con shell `/sbin/nologin`.
  2. Configurar `/etc/skel` para que los admins nuevos tengan el `umask` correcto (027).
  3. Aplicar límites estrictos de `nofile=1048576` y `nproc=4096` para el usuario `kubelet`.
  4. Asegurar que la autenticación de admins venga vía LDAP (simulado) desde `node03`.
  5. Generar un reporte de cumplimiento en la bóveda de `node03`.

---

### 💡 Por qué esta progresión te hace un mejor DevOps:
*   **USR-003 (Límites)** te enseña por qué los Pods de Kubernetes se quedan en estado `OOMKilled` o `CrashLoopBackOff` si el nodo no está bien configurado.
*   **USR-004 (LDAP)** es exactamente lo que se usa en empresas reales para integrar Kubernetes con Active Directory o Keycloak.
*   **USR-006 (Capstone)** simula una tarea real de un Ingeniero de Plataforma (Platform Engineer): escribir un script de Ansible/Terraform que deje un nodo listo y seguro para K8s.


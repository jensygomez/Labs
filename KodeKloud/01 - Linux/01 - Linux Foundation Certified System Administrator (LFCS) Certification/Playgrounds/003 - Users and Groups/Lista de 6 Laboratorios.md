


---

### 🗺️ Ruta de Práctica: Users & Groups Avanzado (L2 + DevOps/K8s)

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
*   **Temas LFCS:** Configure SSH Server, Manage User Authentication Methods, SSH Key-Based Authentication.
*   **Enfoque DevOps/K8s:** Seguridad en acceso a nodos, automatización de despliegues sin contraseñas, principios Zero Trust.
*   **Escenario:** La política de seguridad de la empresa prohíbe la autenticación SSH por contraseña. Debes:

  1. Generar pares de llaves SSH para usuarios específicos en `node01`
2. Distribuir las llaves públicas a `node02` configurando `~/.ssh/authorized_keys`
3. Aplicar restricciones avanzadas en `authorized_keys` (limitar desde qué IP pueden conectarse, comandos específicos)
4. Hardening de `sshd_config` en `node02` (desactivar PasswordAuthentication, PermitRootLogin, etc.)
5. Configurar acceso sin contraseña para automatización (script de despliegue desde `node01` a `node02`)
6. Auditoría de llaves instaladas y reporte a `node03`

#### **5. **Título:** USR-005: SSH Hardening Básico
**Temas:** Configure SSH Server, Manage Access to Root Account
**Enfoque:** Primer paso de seguridad de acceso a un nodo. Es la base de cualquier hardening — sin esto, todo lo demás (sudo, auditoría) es inútil porque la puerta de entrada sigue abierta.
**Escenario:** Una auditoría de seguridad marcó que `root` puede iniciar sesión directamente por SSH en `node02`. Debes deshabilitar `PermitRootLogin`, desactivar `PasswordAuthentication` (forzando autenticación por llave), y reiniciar el servicio `sshd` verificando que la configuración no rompa el acceso actual antes de cerrar la sesión.

---

**Título:** USR-006: Auditoría de Sudo con rsyslog
**Temas:** Manage User Privileges, Manage User Authentication Methods
**Enfoque:** Cumplimiento (compliance). No basta con dar permisos — hay que poder demostrar quién hizo qué y cuándo, algo que cualquier auditoría de seguridad va a pedir.
**Escenario:** No hay registro de quién ejecuta comandos `sudo` en `node02`. Debes configurar `sudo` para que registre todos los comandos ejecutados en un archivo de log separado (`/var/log/sudo.log`) usando `rsyslog`, y verificar que los logs se generen correctamente al usar comandos privilegiados.

---

**Título:** USR-007: Restricción de `su -` por Grupo
**Temas:** Manage Access to Root Account, Local User/Group Management
**Enfoque:** Principio de menor privilegio aplicado a la escalación de privilegios — solo un grupo controlado debería poder volverse root, no cualquier usuario del sistema.
**Escenario:** Cualquier usuario en `node02` puede ejecutar `su -` e intentar volverse root si conoce la contraseña. Debes crear (o usar) el grupo `sysadmin`, configurar PAM (`/etc/pam.d/su`) para que solo los miembros de ese grupo puedan ejecutar `su -`, y verificar el bloqueo con un usuario fuera del grupo.

---

**Título:** USR-008: Usuario de Servicio sin Login
**Temas:** Local User/Group Management, Configure User Resource Limits
**Enfoque:** Cómo se preparan las cuentas de servicio en producción — nunca con shell interactiva, siempre con límites de recursos definidos desde el principio.
**Escenario:** Necesitas crear el usuario de servicio `kubelet` en `node02`, con shell `/sbin/nologin` (no debe poder iniciar sesión interactiva), y aplicarle límites estrictos de `nofile=1048576` y `nproc=4096` vía `/etc/security/limits.conf` o un drop-in de systemd.

---

**Título:** USR-009: Plantilla de Usuario Estándar (/etc/skel)
**Temas:** Manage Template User Environment, Manage System-Wide Environment Profiles
**Enfoque:** Estandarización de entornos — que todo usuario nuevo nazca con la configuración de seguridad correcta, sin depender de que el admin se acuerde de aplicarla a mano cada vez.
**Escenario:** Los admins nuevos que se crean en `node02` no tienen un `umask` seguro por defecto. Debes configurar `/etc/skel` y los scripts en `/etc/profile.d/` para que cualquier usuario nuevo herede automáticamente `umask 027`, y comprobar el resultado creando un usuario de prueba.

---

**Título:** USR-010: Capstone — Hardening de Nodo para Kubernetes
**Temas:** Integración de todos los temas anteriores (USR-005 a USR-009)
**Enfoque:** Preparación real de un "worker node" antes de unirse a un clúster — este es el ticket que mide si ya integraste todo lo anterior sin guía paso a paso.
**Escenario:** Se te entrega `node02` en estado caótico y debes dejarlo listo como nodo de Kubernetes: SSH hardenizado, sudo con logging, `su -` restringido al grupo `sysadmin`, usuario de servicio `kubelet` con `nologin` y límites de recursos, y `/etc/skel` con `umask 027` para los admins. Al final, debes generar un reporte de cumplimiento y dejarlo en `node03`.
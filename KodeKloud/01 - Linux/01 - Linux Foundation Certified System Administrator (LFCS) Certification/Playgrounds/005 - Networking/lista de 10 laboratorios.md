
¡Excelente elección! El **Multi-Node Ubuntu Playground** de KodeKloud es el entorno perfecto para simular incidentes de red reales de nivel L2/L3. A diferencia de un solo nodo, aquí la complejidad radica en la **comunicación entre sistemas**, lo que es el núcleo de la infraestructura empresarial y DevOps.

Basándome estrictamente en el temario del módulo de **Networking del LFCS** y elevando la dificultad a niveles **6, 7, 8 y 9**, he diseñado una ruta de 10 laboratorios. Cada uno simula un "Ticket de Incidente" realista donde el fallo no es obvio y requiere diagnóstico con herramientas como `ip`, `ss`, `tcpdump`, `journalctl` y `iptables`/`nftables`.



---

### 🗺️ Ruta de Práctica: Networking Avanzado LFCS (Multi-Nodo)
*Arquitectura base: `node01` (Estación de Admin/Jump), `node02` (Servidor de Aplicaciones/Proxy), `node03` (Base de Datos/Vault/Backend).*

#### **1. NET-001: El Candado Oxidado – Bloqueo de Acceso SSH y Resolución de Nombres**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas LFCS:** Configure SSH Servers and Clients, Hostname Resolution.
*   **Escenario:** Tras una "auditoría de seguridad", alguien modificó `sshd_config` y `/etc/nsswitch.conf` en `node02`. Ahora no puedes conectar desde `node01` usando el hostname, y la autenticación por clave falla. Debes restaurar el acceso seguro, corregir la resolución DNS local (`systemd-resolved` o `/etc/hosts`) y asegurar los permisos de `.ssh/`.

#### **2. NET-002: La Paradoja Temporal – Deriva de Reloj y Fallo de Autenticación en Clúster**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas LFCS:** Set and Synchronize System Time Using Time Servers.
*   **Escenario:** Una aplicación distribuida entre `node02` y `node03` está fallando intermitentemente con errores de "Token expirado" o "Certificado no válido". El diagnóstico revela que `node03` tiene una deriva de tiempo de +15 minutos. El servicio `chronyd` está detenido o bloqueado por el firewall local. Debes sincronizar los nodos y asegurar la persistencia del servicio NTP.

#### **3. NET-003: La Interfaz Fantasma – Fallo en el Levantamiento de Interfaces y Enrutamiento**
*   **Dificultad:** 7/10 | **Nivel:** L2/L3
*   **Temas LFCS:** Start, Stop, and Check Status of Network Services, IPv4/IPv6 Networking.
*   **Objetivo**:  Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno y Devops Enginner. 
*   **Escenario:** Tras un reinicio simulado de `node02`, la interfaz de red secundaria (usada para comunicación con `node03`) no levanta. Además, falta una ruta estática crítica. Debes diagnosticar la configuración de red (Netplan o `systemd-networkd`), corregir la sintaxis del archivo YAML/config, aplicar los cambios sin reiniciar el servidor completo y verificar la tabla de enrutamiento (`ip route`).

#### **4. NET-004: El Muro Ciego – Reglas de Firewall Bloquean Tráfico Legítimo**
*   **Dificultad:** 7/10 | **Nivel:** L2/L3
*   **Temas LFCS:** Configure Packet Filtering (Firewall).
*   **Objetivo**:  Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno y Devops Enginner. 
*   **Escenario:** El equipo de seguridad aplicó reglas de `iptables` (o `nftables`) en `node02` de forma agresiva. Ahora, el tráfico de retorno de las conexiones establecidas se está descartando, y los logs de `node03` muestran "Connection timed out". Debes auditar las reglas, identificar la regla que rompe el estado `ESTABLISHED,RELATED`, corregirla y hacerla persistente.

#### **5. NET-005: El Túnel Torcido – Fallo en Redirección de Puertos (DNAT) y Enmascaramiento (SNAT)**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas LFCS:** Port Redirection and Network Address Translation (NAT).
*   **Escenario:** `node03` está en una red aislada (sin IP pública). Se requiere que el tráfico externo que llegue al puerto 8080 de `node02` sea redirigido al puerto 5432 de `node03`. Además, `node03` necesita salida a internet para actualizaciones, pero no tiene gateway. Debes configurar `net.ipv4.ip_forward`, reglas DNAT y SNAT (Masquerade) en `node02`.

#### **6. NET-006: El Eslabón Débil – Configuración Errónea de Bonding y Dispositivos Bridge**
*   **Dificultad:** 8/10 | **Nivel:** L3
*   **Temas LFCS:** Configure Bridge and Bonding Devices.
*   **Escenario:** Se requiere alta disponibilidad de red en `node02`. Se intentó configurar un interfaz `bond0` en modo Active-Backup (o LACP), pero la interfaz está en estado "degraded" o no trafica datos. Debes diagnosticar el estado del bonding (`/proc/net/bonding/bond0`), corregir la configuración de Netplan/systemd-networkd y verificar la conmutación por error (failover) simulando la caída de una interfaz.

#### **7. NET-007: El Mensajero Confundido – Reverse Proxy con Cabeceras Perdidas y Timeout**
*   **Dificultad:** 8/10 | **Nivel:** L3
*   **Temas LFCS:** Implement Reverse Proxies and Load Balancers.
*   **Escenario:** Nginx en `node01` actúa como proxy hacia una app en `node02`. La app funciona, pero registra todas las peticiones como si vinieran de `127.0.0.1` (rompiendo la auditoría) y sufre timeouts intermitentes. Debes corregir las directivas `proxy_pass`, `proxy_set_header` (X-Forwarded-For, Host) y ajustar los tiempos de espera (`proxy_read_timeout`) en Nginx.

#### **8. NET-008: La Balanza Descompensada – Fallo de Conmutación por Error en HAProxy**
*   **Dificultad:** 8/10 | **Nivel:** L3
*   **Temas LFCS:** Implement Reverse Proxies and Load Balancers.
*   **Escenario:** Un clúster de HAProxy en `node01` distribuye tráfico entre `node02` y `node03`. `node03` ha caído, pero HAProxy sigue enviándole tráfico, causando errores 503 para los usuarios. El "health check" está mal configurado. Debes corregir la configuración de HAProxy para que detecte el fallo real (ej. chequeando un endpoint HTTP específico) y retire el nodo del pool automáticamente.

#### **9. NET-009: La Zona Desmilitarizada (DMZ) – Enrutamiento Político y Aislamiento de Segmentos**
*   **Dificultad:** 9/10 | **Nivel:** L3
*   **Temas LFCS:** Packet Filtering, IPv4 Networking, Routing.
*   **Escenario:** Se debe aislar `node03` (Base de Datos). Solo `node02` (App) puede hablar con `node03` por el puerto 5432. `node01` (Admin) solo puede acceder a `node02` por SSH (22) y a `node03` por SSH (2222, mediante port forwarding). Cualquier otro tráfico entre nodos debe ser descartado y registrado (LOG & DROP). Debes implementar esto con `nftables` o `iptables` avanzados.

#### **10. NET-010: El Colapso de la Red – Incidente Compuesto de Enrutamiento, Firewall y Proxy**
*   **Dificultad:** 9/10 | **Nivel:** L3 (Examen Final)
*   **Temas LFCS:** Todos los anteriores integrados.
*   **Escenario:** Un "Capture The Flag" operativo. Se te entrega un entorno de 3 nodos donde una aplicación web de 3 capas (Cliente -> Proxy -> App -> DB) está completamente caída. Los síntomas son mezcla de: resolución DNS fallida, reloj desincronizado, reglas de firewall bloqueando el healthcheck del load balancer y una ruta estática borrada. Debes usar `tcpdump`, `ss`, y `ip` para aislar cada capa, corregir los 4-5 fallos simultáneos y documentar la solución en la bóveda.

---




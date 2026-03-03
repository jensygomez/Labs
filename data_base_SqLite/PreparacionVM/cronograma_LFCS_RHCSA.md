# Cronograma de Estudio — LFCS + RHCSA
> Laboratorio: server01 + sandbox01 (KVM/Rocky Linux 9)  
> Niveles: Básico → Intermedio → Avanzado → Troubleshooting

---


## Bloque 1 — Fundamentos del sistema

| Tema | Básico | Intermedio | Avanzado | Troubleshooting |
|------|--------|------------|----------|-----------------|
| ★ Navegación filesystem | ls, cd, pwd, find básico | find con -exec, locate, stat | find complejo con múltiples condiciones | Localizar archivos huérfanos, buscar por inode |
| ★ Permisos estándar | chmod numérico, chown | chmod simbólico, umask | umask en scripts, permisos por defecto en servicios | Servicio falla por permisos incorrectos |
| ★ Permisos especiales | Qué son SUID/SGID/sticky | Aplicarlos manualmente | Auditar binarios con SUID innecesario | SUID causando escalada de privilegios |
| ★ ACLs | getfacl, setfacl básico | ACLs por defecto en directorios | ACLs en NFS y Samba | ACL que sobreescribe permisos esperados |
| ★ Links | ln -s básico | Hard links y limitaciones | Links en scripts y servicios | Link roto causando fallo de aplicación |
| ★ Compresión | tar czf, tar xzf | tar con bzip2, xz, comparar tamaños | tar incremental, backup con exclude | Restaurar backup corrupto parcialmente |
| ★ Gestión paquetes | dnf install/remove/update | dnf modules, grupos, history | Crear repo local, dnf offline | Dependencia rota, repo corrupto, rpm -V |
| ★ Vim | Modo inserción, guardar, salir | Búsqueda, reemplazar, múltiples archivos | Macros, splits, vimrc básico | Editar archivo de sistema sin romperlo |

---

## Bloque 2 — Usuarios y grupos

| Tema | Básico | Intermedio | Avanzado | Troubleshooting |
|------|--------|------------|----------|-----------------|
| ★ Usuarios | useradd, usermod, userdel | Skeleton dir, defaults en /etc/default/useradd | Usuarios del sistema para servicios | Usuario no puede login, shell inválido |
| ★ Grupos | groupadd, groupmod | Grupos secundarios, newgrp | Estrategia de grupos para equipos | Permisos denegados por grupo incorrecto |
| ★ Contraseñas | passwd básico | chage, políticas de expiración | PAM básico, /etc/security/pwquality.conf | Cuenta bloqueada, expirada |
| ★ Sudoers | Agregar usuario a wheel | /etc/sudoers.d/, comandos específicos | NOPASSWD, restricciones por host | sudo: command not found, visudo roto |

---

## Bloque 3 — Almacenamiento
> Practicar en **sandbox01** con discos virtuales y loop devices

| Tema | Básico | Intermedio | Avanzado | Troubleshooting |
|------|--------|------------|----------|-----------------|
| ★ Particionado | fdisk MBR básico | parted GPT, tipos de partición | Particionado en disco con datos | Tabla de particiones corrupta |
| ★ Filesystems | mkfs.xfs, mkfs.ext4, mount manual | /etc/fstab con opciones, UUID | tune2fs, xfs_admin, quotas | fstab roto, sistema no arranca |
| ★ Swap | mkswap, swapon | Swap en archivo, prioridades | Swappiness, swap en producción | Sistema sin swap, OOM killer |
| ★ LVM | pvcreate, vgcreate, lvcreate | lvextend, lvreduce, resize2fs | Snapshots, pvmove, vgmerge | VG no activa, PV corrupto |
| ★ LUKS | cryptsetup luksFormat básico | /etc/crypttab, automount | LUKS sobre LVM y LVM sobre LUKS | Passphrase olvidada, header corrupto |
| RHCSA Stratis | Concepto y creación básica | Snapshots en Stratis | Stratis vs LVM cuándo usar cada uno | Pool que no monta |
| RHCSA VDO | Concepto de deduplicación | Crear volumen VDO | VDO sobre LVM | VDO que no activa |
| LFCS Cuotas | Concepto y activación | quotacheck, edquota, repquota | Cuotas en XFS vs ext4 | Usuario ignorando cuota, quota.user corrupto |

---

## Bloque 4 — Systemd y procesos

| Tema | Básico | Intermedio | Avanzado | Troubleshooting |
|------|--------|------------|----------|-----------------|
| ★ Servicios | start, stop, status, enable | mask, override con systemctl edit | Dependencias entre servicios, After= Wants= | Servicio en failed, ciclo de reinicios |
| ★ Targets | Listar targets, cambiar default | Aislar target, rescue, emergency | Crear target propio | Sistema arranca en target incorrecto |
| ★ Unit files | Leer un unit file | Crear service unit propio | Type=forking vs simple vs notify | Unit file con error de sintaxis |
| ★ Journald | journalctl básico | Filtrar por tiempo, servicio, prioridad | Persistencia de logs, reenvío a syslog | Logs que no aparecen, journal corrupto |
| ★ Procesos | ps aux, top, kill | nice, renice, ionice, pgrep, pkill | cgroups básico, limits en unit files | Proceso zombie, consumo de CPU inesperado |
| ★ Cron | Sintaxis básica, crontab -e | /etc/cron.d/, anacron, variables | Cron como usuario del sistema | Cron que no ejecuta, PATH incorrecto |
| ★ Timers | Concepto vs cron | Crear timer + service pair | Timers con calendario complejo | Timer que no dispara, dependencia faltante |

---

## Bloque 5 — Networking

| Tema | Básico | Intermedio | Avanzado | Troubleshooting |
|------|--------|------------|----------|-----------------|
| ★ IPs e interfaces | nmcli con asistente, nmtui | nmcli en línea de comandos, conexiones múltiples | Bonding, teaming, VLANs básico | Interfaz sin IP, conexión que no levanta |
| ★ Routing | ip route show, default gateway | Rutas estáticas persistentes | Routing entre subnets, ip rule | Ruta incorrecta, tráfico que no llega |
| ★ SSH | ssh, scp, ssh-keygen básico | ssh_config, authorized_keys, agent | Tunneling, ProxyJump, bastión | Conexión rechazada, key no acepta |
| ★ firewalld | zones, services básico | Rich rules, port forwarding | firewalld con nftables backend | Servicio bloqueado, regla que no aplica |
| ★ Diagnóstico | ping, ip addr, ss -tunlp | traceroute, nmap básico, tcpdump simple | tcpdump avanzado, análisis de tráfico | Red que funciona a medias, paquetes perdidos |

---

## Bloque 6 — Servicios de red
> Configurar en **server01**, consumir desde **client01** y **client02**

| Tema | Básico | Intermedio | Avanzado | Troubleshooting |
|------|--------|------------|----------|-----------------|
| ★ DNS/BIND | Concepto, cliente /etc/resolv.conf | Configurar servidor caché | Zona autoritativa, registros A, MX, PTR | Resolución que falla, named no arranca |
| ★ DHCP | Concepto, cliente | Configurar servidor, rangos, reservas | DHCP con opciones avanzadas, PXE básico | Cliente no obtiene IP, conflicto de IPs |
| ★ NFS | Montar share existente | Configurar servidor, /etc/exports | Automount con autofs | Permiso denegado en mount, stale handle |
| ★ Samba | Concepto, smbclient | Configurar share básico | Share con autenticación, integración AD básica | Cliente Windows no ve share, permisos Samba vs Linux |
| ★ Apache | Instalar, página básica | Virtual hosts, logs | SSL con certificado autofirmado | Error 403/500, SELinux bloqueando httpd |
| LFCS FTP | vsftpd instalación básica | Usuarios virtuales, chroot | FTP sobre TLS | Conexión rechazada, modo pasivo |
| ★ Chrony | Concepto NTP | Configurar cliente chrony | Configurar servidor NTP local | Tiempo desincronizado, chrony no sincroniza |

---

## Bloque 7 — Seguridad

| Tema | Básico | Intermedio | Avanzado | Troubleshooting |
|------|--------|------------|----------|-----------------|
| ★ SELinux | Modos (enforcing/permissive/disabled), getenforce | chcon, restorecon, semanage fcontext | Booleans, políticas personalizadas, audit2allow | Servicio bloqueado por SELinux, AVC denied |
| ★ SSH hardening | Deshabilitar root login | Cambiar puerto, AllowUsers, MaxAuthTries | Certificados SSH, 2FA básico | Acceso perdido por hardening mal aplicado |
| ★ firewalld avanzado | Zonas por interfaz, panic mode | nftables directo, ipsets | Reglas complejas multi-zona | Regla que bloquea tráfico legítimo |
| LFCS Fail2ban | Concepto e instalación | Configurar jail SSH | Jails personalizados | IP legítima bloqueada |

---

## Bloque 8 — Contenedores con Podman
> Solo RHCSA (pero útil para el día a día como Sysadmin)

| Tema | Básico | Intermedio | Avanzado | Troubleshooting |
|------|--------|------------|----------|-----------------|
| ★ Podman básico | pull, run, ps, stop, rm | exec, logs, inspect, volumes | Redes de contenedores, pod concept | Contenedor que no arranca, puerto ocupado |
| ★ Rootless | Concepto y diferencias | Ejecutar servicios sin root | Namespaces de usuario | Permiso denegado en rootless |
| ★ Containerfile | FROM, RUN, CMD básico | Capas, COPY, ENV, EXPOSE | Multi-stage builds, optimización | Build que falla, dependencia no encontrada |
| ★ Systemd + Podman | Concepto | podman generate systemd | Autostart con loginctl enable-linger | Servicio que no inicia en boot |

---

## Bloque 9 — Scripting Bash

| Tema | Básico | Intermedio | Avanzado | Troubleshooting |
|------|--------|------------|----------|-----------------|
| ★ Fundamentos | Variables, echo, read, comentarios | Condicionales if/else, case | Funciones, recursión básica | Script que no ejecuta, shebang incorrecto |
| ★ Control de flujo | for, while básico | until, break, continue, select | Procesamiento de argumentos con getopts | Loop infinito, condición que nunca se cumple |
| ★ Procesamiento texto | grep básico, cut | awk columnas, sed sustitución | awk programas complejos, sed multiline | Regex que no matchea, encoding UTF-8 |
| ★ Scripts de admin | Script de backup simple | Script con logging y manejo de errores | Script idempotente para configuración | Script que falla silenciosamente, exit codes |

---

## Bloque 10 — Troubleshooting puro
> El bloque más importante. Practicar hasta que sea instintivo.

| Escenario | Básico | Intermedio | Avanzado |
|-----------|--------|------------|----------|
| ★ Sistema no arranca | Entrar a rescue mode | Reparar grub, regenerar initramfs | Recuperar sin live CD usando chroot |
| ★ Reset root password | rd.break método | Método con init=/bin/bash | Sin acceso a consola física |
| ★ fstab roto | Identificar el error en rescue | Reparar y verificar con mount -a | fstab con LUKS y LVM combinados |
| ★ SELinux bloquea | Identificar con ausearch/journalctl | Aplicar fix con restorecon | Crear política personalizada con audit2allow |
| ★ Red no conecta | Verificar interfaz, IP, gateway | Verificar firewall, routing, DNS en orden | Captura de tráfico para diagnosticar |
| ★ Servicio no arranca | Leer status y journalctl | Identificar dependencias faltantes | Conflicto de puertos + SELinux simultáneo |
| ★ Disco lleno | df, du para localizar | Limpiar logs, paquetes, cache | Extender LV en caliente sin desmontar |

---

## Infraestructura del laboratorio

```
PC del hijo (KVM + Virt-Manager)
├── server01  — 2 vCPUs, 4GB RAM, disco 20GB + disco vacío 15GB
│   ├── client01  (contenedor Podman con systemd)
│   └── client02  (contenedor Podman con systemd)
└── sandbox01 — 1 vCPU, 1.5GB RAM, disco 15GB + 2 discos vacíos (10GB c/u)



Tu laptop
└── Terminal SSH hacia todo lo anterior
```

---

*Última actualización: Febrero 2026*

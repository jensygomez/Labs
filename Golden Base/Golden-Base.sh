#!/bin/bash
# ===================================================================================
# LABORATORIO LINUX PARA CERTIFICACIÓN LFCS/LFCE
# Topología: Infraestructura completa con namespaces
# Versión: 2.0 - Escalable y automatizada
# ===================================================================================
# TOPOLOGÍA DISTRIBUIDA (MEJOR PARA APRENDER)
# ===================================================================================
#
#                           ┌─────────────────────────────────────┐
#                           │           INTERNET (NAT)            │
#                           └───────────────┬─────────────────────┘
#                                           │
#           ┌───────────────────────────────┴─────────────────────────────────┐
#           │                     CORE-GW (ns-gw-basic)                       │
#           │                  (SOLO Router + NAT + Firewall)                 │
#           │                        br0: 10.0.0.1/24                         │
#           └───────────────────────────────┬─────────────────────────────────┘
#                                           |           
#           ┌─────────────────────┐─────────────────────┐─────────────────────┐
#           │                     │                     │                     │
#  ┌────────┴────────┐   ┌────────┴────────┐   ┌────────┴────────┐   ┌────────┴────────┐
#  │    ns-srv       │   │      ns-rh      │   │      ns-sys     │   │      ns-infra   │
#  │  (Servicios)    │   │  (Empleados)    │   │     (Admin)     │   │      (Infra)    | 
#  └────────┬────────┘   └────────┬────────┘   └────────┬────────┘   └────────┬────────┘
#           │                     │                     │                     │
#   ┌───────┴──────┐       ┌──────┴──────┐         ┌────┴──────┐       ┌──────┴──────┐
#   │   serv-ldap  │       │ pc-rh1      │         │ pc-sys1   │       │ pc-dns      │
#   │   10.0.0.11  │       │ 10.0.0.21   │         │ 10.0.0.31 │       │ 10.0.0.2    │
#   ├──────────────┤       ├─────────────┤         ├───────────┤       ├──────────────┤
#   │    ser-fs    │       │ pc-rh2      │         │           │       │ pc-dhcp      │
#   │   10.0.0.12  │       │ 10.0.0.22   │         │           │       │ 10.0.0.2     │
#   └──────────────┘       ├─────────────┤         └───────────┘       └──────────────┘
#                          │ pc-rh3      │
#                          │ 10.0.0.23   │
#                          └─────────────┘

# ===================================================================================
#  [Propósito del Lab]:
#  1. LDAP: Centraliza usuarios (No más 'useradd' manual en cada VM).
#  2. FS:  Servidor NFS/Samba para que /home/usuario esté en todas las VMs.
#  3. SYS: Tu consola para administrar RH y SRV vía SSH.
# ===================================================================================
# ================================================================================
# FILOSOFÍA: ARQUITECTURA DE SISTEMAS LINUX
# ================================================================================
#
# 1. NAMESPACES = AISLAMIENTO QUIRÚRGICO
# 2. BRIDGE = SWITCH EN MEMORIA (sin hardware)
# 3. VETH = CABLES VIRTUALES INVISIBLES
# 4. KERNEL = ÚNICA FUENTE DE VERDAD
#
# ================================================================================

# ===================================================================================
# TABLA DE DIRECCIONAMIENTO IP - LABORATORIO LINUX
# ===================================================================================
# RED BASE: 10.0.0.0/24 (254 hosts disponibles)
# GATEWAY: 10.0.0.1
# MÁSCARA: 255.255.255.0
# ===================================================================================

# -----------------------------------------------------------------------------------
# 1. CORE-GW (ns-gw-basic)
# -----------------------------------------------------------------------------------
# Función: Router, NAT, Firewall
# Interfaz en bridge: br0 = 10.0.0.1/24
# Interfaz a Internet: eth0 (DHCP desde VM anfitriona)

# -----------------------------------------------------------------------------------
# 2. ns-infra (Servicios de Infraestructura)
# -----------------------------------------------------------------------------------
# Bridge interno: br-infra (aislado o conectado a br0)
#
# pc-dns (10.0.0.2/24)
#   ├── Servicios: DNS (dnsmasq/bind9)
#   └── Responde por: dns.lab.local, ns1.lab.local
#
# pc-dhcp (10.0.0.2/24) - MISMA IP (mismo PC físico)
#   ├── Servicios: DHCP (dnsmasq/isc-dhcp-server)
#   └── Rango DHCP: 10.0.0.100 - 10.0.0.200

# -----------------------------------------------------------------------------------
# 3. ns-srv (Servidores de Aplicación)
# -----------------------------------------------------------------------------------
# Bridge interno: br-srv
#
# serv-ldap (10.0.0.11/24)
#   ├── Servicios: OpenLDAP, SSSD
#   ├── Nombres: ldap.lab.local, auth.lab.local
#   └── Puertos: 389 (LDAP), 636 (LDAPS)
#
# serv-fs (10.0.0.12/24)
#   ├── Servicios: NFS, Samba (opcional)
#   ├── Nombres: fs.lab.local, storage.lab.local, nfs.lab.local
#   └── Puertos: 2049 (NFS), 445 (Samba)

# -----------------------------------------------------------------------------------
# 4. ns-rh (Clientes/Empleados)
# -----------------------------------------------------------------------------------
# Bridge interno: br-rh
#
# pc-rh1 (10.0.0.21/24)
#   ├── Rol: Estación de trabajo 1
#   └── Hostname: rh1.lab.local
#
# pc-rh2 (10.0.0.22/24)
#   ├── Rol: Estación de trabajo 2
#   └── Hostname: rh2.lab.local
#
# pc-rh3 (10.0.0.23/24)
#   ├── Rol: Estación de trabajo 3
#   └── Hostname: rh3.lab.local

# -----------------------------------------------------------------------------------
# 5. ns-sys (Administración)
# -----------------------------------------------------------------------------------
# Bridge interno: br-sys
#
# pc-sys1 (10.0.0.31/24)
#   ├── Rol: Consola de administración
#   ├── Hostname: sysadmin.lab.local
#   ├── Herramientas: ssh, scp, rsync, ansible (futuro)
#   └── Acceso: SSH a todos los PCs

# -----------------------------------------------------------------------------------
# 6. RANGO DHCP (RESERVADO)
# -----------------------------------------------------------------------------------
# Rango dinámico: 10.0.0.100 - 10.0.0.200
# ├── 10.0.0.100 - 10.0.0.120: Reservado para futuros clientes
# ├── 10.0.0.121 - 10.0.0.150: Reservado para contenedores temporales
# └── 10.0.0.151 - 10.0.0.200: Reservado para prácticas/experimentos

# -----------------------------------------------------------------------------------
# 7. FUTURAS EXPANSIONES (ns-automation, ns-monitor, ns-backup)
# -----------------------------------------------------------------------------------
#
# ns-automation (10.0.0.100/24) - IP FIJA
#   ├── pc-ansible: 10.0.0.100
#   └── Servicios: Ansible, Git, Jenkins
#
# ns-monitor (10.0.0.101/24) - IP FIJA
#   ├── pc-prometheus: 10.0.0.101
#   ├── pc-grafana: 10.0.0.101 (mismo PC)
#   └── Servicios: Prometheus, Grafana, Alertmanager
#
# ns-backup (10.0.0.102/24) - IP FIJA
#   ├── pc-backup: 10.0.0.102
#   └── Servicios: Bacula, Backup NFS
#
# ns-ldap2 (10.0.0.13/24) - Réplica LDAP
# ns-fs2 (10.0.0.14/24) - Réplica NFS
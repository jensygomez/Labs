
# Ecosistema Lab Sysadmin Linux

Este repositorio documenta tu ecosistema de lab actual en MX Linux host con libvirt/virt-manager, usando network namespaces para simular una infraestructura 3-tier segura con VLANs aisladas, FW/GATEWAY, servicios web/DB y sysadmin remoto vía VPN.  Incluye automatización para RHCSA-style labs, incidentes NOC y persistencia con systemd.[^1][^2]

## Arquitectura General

El setup simula un entorno production con enrutamiento, firewalls (firewalld/iptables en namespaces) y acceso segmentado. Host OS actúa como gateway con bridges para VLANs.

```
[ MUNDO EXTERIOR ]
(VPN Sysadmin)
       |
       ▼
                                         |
                          ┌──────────────┴──────────────┐
                          |      ACCESO GESTIÓN SSH     | (IP: 192.168.122.x)
                          └──────────────┬──────────────┘
                                         ▼
                          [ FW / GATEWAY (HOST OS) ]
                          (Enrutamiento y Seguridad)
                                         |
          ┌──────────────────────────────┼──────────────────────────────┐
          |                              |                              |
  [ VLAN 10: SERVICIOS ]       [ VLAN 20: USUARIOS ]          [ VLAN 30: GESTIÓN ]
    (Bridge: br-srv)             (Bridge: br-cli)               
     10.10.10.0/24                10.10.20.0/24                  
          |                              |                       
          ▼                              ▼                       
    [ NS-SERVICES ]                [ NS-CLIENT ]                 
    (10.10.10.10)                  (10.10.20.20)                 
    - Nginx Web                    - Estación de                 
    - Dnsmasq DNS                    Trabajo                     
          |                                                     
          └──────────────┬──────────────┐                        
                         ▼              |                        
               [ VLAN 90: BÚNKER DATOS ] |                        
                 (Bridge: br-data)      |                        
                  10.10.90.0/24         |                        
                         |              |                        
                         ▼              |                        
                   [ NS-STORAGE ] ──────┼────────────────────────
                   (10.10.90.50)           [ NS-SYSADMIN ]
                   - MariaDB Server       (172.16.0.100)
                                         - Monitoreo
                                         - Auditoría
```


## Componentes Detallados

| Namespaces/Servicios | IP/Red | Bridge/VLAN | Funciones Principales |
| :-- | :-- | :-- | :-- |
| NS-SERVICES | 10.10.10.10 | br-srv / VLAN10 | Nginx web server, Dnsmasq DNS |
| NS-CLIENT | 10.10.20.20 | br-cli / VLAN20 | Estación de trabajo usuario |
| NS-STORAGE | 10.10.90.50 | br-data / VLAN90 | MariaDB Server DB bunker |
| NS-SYSADMIN | 172.16.0.100 | VLAN30 Gestión | Monitoreo, auditoría vía VPN |
| FW/GATEWAY | 192.168.122.x | Host OS | Enrutamiento, firewalld, SSH acceso |

## Configuración y Uso

- **Inicio rápido**: `ip netns exec NS-SERVICES systemctl status nginx` (usa slices systemd para persistencia).[^1]
- **VPN Sysadmin**: Configura WireGuard en host para acceso remoto a 172.16.0.100; reglas FW permiten solo monitoreo → storage.
- **Health check**: Script `/usr/local/bin/lab-health` verifica conectividad (curl 10.10.10.10, mysql 10.10.90.50).[^2]
- **Snapshots libvirt**: Crea snapshots pre/post-incidentes para RHCSA practice.
- **Archivos clave**: `/etc/lab.info` (resumen), `/var/log/lab-setup.log`, `/etc/lab-configs/iptables-*.rules`.


## Scripts de Automatización

- `lab-setup.sh`: Despliega todo idempotentemente (dnf, namespaces, servicios).[^1]
- `lab-fw-save.sh`: Persiste iptables en reboots.[^1]
- Ansible/Terraform compatibles para IaC (ver historial J02).[^3]

¡Ecosistema listo para simular fallos NOC y certs Linux! Expande con Docker si necesitas.
<span style="display:none">[^10][^11][^12][^13][^4][^5][^6][^7][^8][^9]</span>

<div align="center">⁂</div>

[^1]: projects.J02_setup

[^2]: projects.rhcsa_lab_trainer

[^3]: projects.linux_lab_course

[^4]: https://www.perplexity.ai/search/11a2ed70-e590-4bf3-94a1-e2fad0f6a848

[^5]: https://www.perplexity.ai/search/7c819665-0e86-4623-baa5-a41a980ca84c

[^6]: interests.linux_namespaces

[^7]: work.devops_infrastructure

[^8]: work.networking_dns_setup

[^9]: work.environment

[^10]: work.role

[^11]: tools.virtualization_libvirt

[^12]: work.system_administration

[^13]: https://www.perplexity.ai/search/f0f2ced6-3322-4a22-835f-7e55cc00a5a6


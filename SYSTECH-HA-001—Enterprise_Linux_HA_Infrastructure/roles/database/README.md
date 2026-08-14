# Role: Database (MariaDB)

Este rol despliega, asegura y aprovisiona un servidor **MariaDB** en la infraestructura de **SYSTECH-HA-001**. Está diseñado con lógica multi-familia OS (soporta tanto Debian/Ubuntu como RedHat/AlmaLinux) e implementa idempotencia total mediante autenticación basada en socket e integración con `/root/.my.cnf`.

## Requisitos

- Colección Ansible: `ansible.mysql` (`ansible-galaxy collection install community.mysql` / `ansible.mysql`).
- Paquete en el objetivo: `python3-pymysql` (instalado automáticamente por el rol).

## Variables del Rol (`defaults/main.yml`)

| Variable | Valor por Defecto | Descripción |
|---|---|---|
| `db_port` | `3306` | Puerto de escucha de MariaDB |
| `db_bind_address` | `"0.0.0.0"` | Dirección IP de bind para conexiones de red |
| `db_root_password` | `"Password123"` | Contraseña del usuario `root` de MariaDB |
| `db_name` | `"acme_db"` | Nombre de la base de datos inicial de la aplicación |
| `db_user` | `"acme_user"` | Usuario de la aplicación con acceso remoto |
| `db_password` | `"Password123"` | Contraseña del usuario de la aplicación |
| `db_allowed_host_pattern` | `{{ ansible_default_ipv4.network }}/{{ ansible_default_ipv4.netmask }}` | Patrón/máscara de red autorizada para conexiones remotas |

## Tareas Principales

1. **Instalación:** Instala MariaDB Server, Client y `python3-pymysql` usando `apt` o `dnf` según la familia del SO.
2. **Configuración:** Despliega la plantilla `50-server.cnf.j2` habilitando la escucha en red (`bind-address`).
3. **Hardening & Idempotencia:**
   - Establece contraseña a `root` mediante el socket UNIX local.
   - Genera el archivo `/root/.my.cnf` con permisos `0600` para asegurar ejecuciones idempotentes posteriores.
   - Elimina usuarios anónimos y la base de datos `test`.
4. **Provisión:** Crea la base de datos de aplicación `acme_db` y el usuario `acme_user` acotado dinámicamente al CIDR de la subred.

## Uso

```bash
ansible-playbook site.yml --tags database

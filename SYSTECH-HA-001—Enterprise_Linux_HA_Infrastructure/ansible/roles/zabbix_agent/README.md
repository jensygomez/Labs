# Integración de roles/zabbix_agent en SYSTECH-HA-001

## 1. Copiar el rol
Extrae este directorio como `roles/zabbix_agent/` dentro del repo
(mismo nivel que `roles/zabbix_server/`, `roles/linux_baseline/`, etc.).

## 2. Verificar/agregar collections requeridas
Solo necesarias si vas a usar `zabbix_agent_manage_firewall: true`.
Agrega a `requirements.yml` si no están ya:

```yaml
collections:
  - name: ansible.posix     # firewalld (RedHat)
  - name: community.general # ufw (Debian)
```

```bash
ansible-galaxy collection install -r requirements.yml
```

## 3. Definir el grupo en el inventario

En `inventories/production/hosts.yml`, agrega (o reutiliza si ya existe
un grupo equivalente) un grupo `zabbix_agents` que agrupe los 5 nodos:

```yaml
all:
  children:
    zabbix_agents:
      hosts:
        server01:
        server02:
        server03:
        lxc01:
        lxc02:
```

Si `hosts.yml` ya organiza los nodos en otros grupos (ej. `db_nodes`,
`lb_nodes`, `lxc_nodes`), no hace falta duplicar hosts: puedes armar
`zabbix_agents` como grupo de grupos:

```yaml
zabbix_agents:
  children:
    vm_nodes:      # si ya agrupa server01/02/03
    lxc_nodes:     # si ya agrupa lxc01/lxc02
```

## 4. Variables por host (opcional)
Si el `Hostname` registrado en la interfaz web de Zabbix no coincide
1:1 con `inventory_hostname`, sobreescribe en `host_vars/<nodo>.yml`:

```yaml
zabbix_agent_hostname: "server01.systech.lab"
```

## 5. Agregar el play en site.yml

```yaml
- name: Desplegar Zabbix Agent 2
  hosts: zabbix_agents
  become: true
  roles:
    - zabbix_agent
```

Colócalo DESPUÉS del play de `linux_baseline` (ya que asume usuarios,
repos base y hardening ya aplicados) y puede ir en paralelo/antes o
después del play de `zabbix_server` — no depende de él, solo necesita
saber su IP (`zabbix_server_ip`, default `10.10.10.40`).

## 6. Ejecutar solo contra este grupo (recomendado la primera vez)

```bash
ansible-playbook site.yml --limit zabbix_agents --check   # dry-run
ansible-playbook site.yml --limit zabbix_agents           # aplicar
```

## 7. Verificar en el servidor Zabbix

Los hosts deben existir previamente en la interfaz web de Zabbix
(Data collection → Hosts) con el mismo nombre que `zabbix_agent_hostname`,
o los checks activos van a fallar con `"active check not found"`.
Verificación rápida desde el propio nodo:

```bash
zabbix_agent2 -t agent.ping
systemctl status zabbix-agent2
ss -tlnp | grep 10050
```

Y desde el Zabbix Server (check pasivo):

```bash
zabbix_get -s 10.10.10.2X -k agent.ping
```


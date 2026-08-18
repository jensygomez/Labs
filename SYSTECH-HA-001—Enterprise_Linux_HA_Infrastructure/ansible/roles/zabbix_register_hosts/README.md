# Integración de roles/zabbix_register_hosts

## 1. Copiar el rol
Extrae como `roles/zabbix_register_hosts/` (mismo nivel que `roles/zabbix_agent/`).

## 2. Agregar la collection requerida

`requirements.yml`:
```yaml
collections:
  - name: community.zabbix
```

```bash
ansible-galaxy collection install -r requirements.yml
```

## 3. Instalar la dependencia Python dentro del contenedor de control

El módulo `community.zabbix.zabbix_host` necesita el paquete Python
`zabbix-utils`. Agrega esta línea al `Dockerfile` (junto a donde ya
instalas otras herramientas) y reconstruye la imagen:

```dockerfile
RUN pip install --break-system-packages zabbix-utils
```

```bash
podman build -t systech-control -f dockerfile/Dockerfile .
```

Si no reconstruyes la imagen, el playbook va a fallar con algo como
`No module named 'zabbix_utils'` — no es un error de tu rol, es que falta
la librería en el contenedor.

## 4. Password del Admin de Zabbix en el Vault

Ya lo agregaste manualmente:
```yaml
vault_zabbix_admin_password: "zabbix"
```
(pendiente: cambiarlo del default una vez que todo el flujo esté probado)

## 5. Agregar el play en site.yml

Después de la Fase 03 (Zabbix Agent), agrega una Fase 03b — separada,
porque esta NO se ejecuta "en" los nodos, se ejecuta desde el control
node hacia la API:

```yaml
# ------------------------------------------------------------------------------
# FASE 03b: REGISTRO DE HOSTS EN ZABBIX (vía API, idempotente)
# ------------------------------------------------------------------------------
- name: "Phase 03b | Register hosts in Zabbix via API"
  hosts: "ha_nodes:lb_nodes"
  become: false
  gather_facts: false
  roles:
    - role: zabbix_register_hosts
      tags: zabbix_register
```

`gather_facts: false` porque no hace falta (la tarea usa `ansible_host`
del inventario, no facts del sistema remoto) y así corre más rápido.

## 6. Ejecutar SOLO contra las 3 VMs por ahora

Ya que decidiste probar primero con server01/02/03 antes de tocar los LXC:

```bash
ansible-playbook -i ansible/inventories/production/hosts.yml ansible/site.yml \
  --tags zabbix_register --limit ha_nodes --ask-vault-pass
```

`--limit ha_nodes` sobre-restringe el `hosts: "ha_nodes:lb_nodes"` del play
para que, aunque el play ya cubra los 5, esta corrida puntual solo toque
las 3 VMs. Cuando confirmes que server01/02/03 aparecen bien en la GUI,
corres sin `--limit` para sumar lxc01/lxc02.

## 7. Verificar

En la GUI: **Data collection → Hosts** — deberías ver `server01`,
`server02`, `server03` con:
- Grupo: Linux servers
- Template: Linux by Zabbix agent active
- Estado del ZBX (ícono verde) — puede tardar 1-2 min en ponerse verde
  mientras el agente hace el primer check-in activo.

Por CLI, sin abrir el navegador:
```bash
ssh ansible@10.10.10.21 "sudo tail -20 /var/log/zabbix/zabbix_agent2.log"
```
Busca una línea tipo `active check configuration update ... started to
succeed` — confirma que el agente encontró su host en el server.


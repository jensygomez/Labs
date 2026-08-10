# Migración inc-010: Bash → Ansible

## Cómo correrlo

Copiá esta carpeta (`roles/`, `group_vars/`, `inc-010.yml`) dentro de tu
`~/Labs/lxd-pilot/`, al mismo nivel que tu `inventory.ini` real (el que
genera Terraform). NO copies `inventory.ini.example` — es solo referencia
de la forma que deben tener los grupos `app_fleet` y `monitoring`.

Instalar Ansible si no lo tenés:
```bash
sudo dnf install -y ansible-core   # o: pip install ansible-core --user
```

Correr el playbook completo (equivalente a correr el script bash entero):
```bash
ansible-playbook -i inventory.ini inc-010.yml
```

Solo sintaxis, sin tocar nada (rápido, para revisar cambios antes de aplicar):
```bash
ansible-playbook -i inventory.ini inc-010.yml --syntax-check
ansible-playbook -i inventory.ini inc-010.yml --check --diff
```

## Mapeo Steps del bash original → Plays de Ansible

| Bash (inc-010-*.sh)                          | Ansible (inc-010.yml)              |
|-----------------------------------------------|-------------------------------------|
| Step 0 (verificar infra)                      | Ansible falla solo si no conecta — no hace falta un check explícito |
| Step 1 (crear bucket S3)                      | `roles/inc-010/tasks/deploy.yml` (primera tarea) |
| Step 2 (instalar nginx/curl)                  | `roles/common/tasks/main.yml`      |
| Step 3 (deploy pipeline order-gen/s3-backend/order-sync) | `roles/inc-010/tasks/deploy.yml` + templates |
| Step 4 (node_exporter)                        | `roles/common/tasks/main.yml`      |
| Step 5 (regla de alerta Prometheus)           | `roles/inc-010/tasks/deploy.yml` (bloque final) |
| Step 6 (esperar baseline)                     | Play "Step C" en `inc-010.yml`     |
| Step 7 (inyectar fault)                       | `roles/inc-010/tasks/inject_fault.yml` |
| Step 8 (ticket en motd)                       | `roles/common/tasks/deploy_ticket.yml` |
| Step 9 (reboot)                               | Dentro de `inject_fault.yml`, módulo `ansible.builtin.reboot` |
| Step 10 (verificación con $VERIFY_OK mudo)    | `roles/inc-010/tasks/verify.yml` — cada check falla por separado con mensaje propio |

## El bug que arrastramos desde bash, ya corregido acá

`s3-backend.sh` ya NO confía en que el AWS CLI falle si faltan credenciales
(FakeCloud acepta requests sin autenticar, así que ese fallo nunca iba a
ocurrir). Ahora chequea un flag file determinístico
(`/var/lib/aws-creds-setup/.ready`) escrito por `aws-creds-setup.service`.
Sin la dependencia (`Requires=`/`After=`), hay una carrera real entre
ambos units — con el flag file, la carrera SIEMPRE es detectable, no
depende de timing de arranque de procesos.

## Qué es reusable para los próximos incidentes

- `roles/common/` completo → sirve para inc-011 en adelante tal cual.
- `roles/common/tasks/assert_http_ok.yml` y `assert_boot_state.yml` →
  reusalos en cualquier incidente que necesite verificar salud HTTP o
  estado de boot.
- `roles/inc-010/templates/*.j2` → reusables SOLO si diseñás otro
  incidente sobre el mismo pipeline order-gen/s3-backend/order-sync.
- Para un incidente nuevo con un stack distinto: copiá la carpeta
  `roles/inc-010/` como plantilla, renombrala, y quedate solo con
  `tasks/deploy.yml`, `tasks/inject_fault.yml`, `tasks/verify.yml`,
  `vars/main.yml` como los 4 archivos que sí tenés que reescribir.

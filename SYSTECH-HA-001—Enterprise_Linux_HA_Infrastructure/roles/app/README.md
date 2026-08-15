# Role: app

## Descripción
Despliega el runtime de la capa de aplicación: Python3 + venv + Flask +
Gunicorn, gestionado por systemd, que conecta a MariaDB (`db01`) y expone
un endpoint que devuelve el hostname del nodo que respondió (para
verificar balanceo de HAProxy más adelante).

## Qué hace
1. Crea usuario de sistema dedicado (`appsvc`, sin login) para correr el proceso.
2. Instala Python3 y dependencias del sistema (RedHat family vía dnf).
3. Crea virtualenv en `/opt/acme_app/venv`.
4. Instala `flask`, `gunicorn`, `pymysql` dentro del venv.
5. Despliega `app.py` (código estático, módulo `copy`).
6. Templa archivo de entorno (`app_env`) con credenciales de DB — nunca
   hardcodeadas en `app.py`.
7. Templa unit file de systemd (`gunicorn.service`).
8. Habilita y arranca el servicio `gunicorn`.

## Variables (defaults/main.yml)
| Variable | Descripción |
|---|---|
| `app_port` | Puerto donde escucha Gunicorn (`8000`) |
| `app_install_dir` | Directorio de instalación (`/opt/acme_app`) |
| `app_system_user` | Usuario Linux que corre el servicio (`appsvc`) |
| `app_db_host` | Host de MariaDB, resuelto dinámicamente vía `hostvars['db01']` |
| `app_db_name` | Base de datos (`acme_db`) |
| `app_db_user` | Usuario MySQL de la app (`app_user`) |
| `app_db_password` | Password vaulteada (`vault_app_db_password`) |

## Dependencias
- Requiere que `db_seed` ya haya corrido (tabla y usuario de DB existentes).
- Requiere conectividad TCP 3306 desde el nodo app hacia `db01`.

## Tags
`app`

## Estado actual
Aplicado solo a `server01` (validación inicial). Pendiente extender a
`server02`/`server03` y configurar `proxy_pass` en el rol `nginx` para
integración completa vía VIP.

## Validación manual
```bash
ansible server01 -m command -a "curl -s http://127.0.0.1:8000/"
```

# Role: db_seed

## Descripción
Popula la base de datos `acme_db` con el esquema inicial y datos de prueba,
y crea el usuario de aplicación con privilegios mínimos (SELECT únicamente).

## Qué hace
1. Templa y copia `schema.sql.j2` a `db01` (CREATE TABLE + INSERT IGNORE).
2. Importa el schema con `community.mysql.mysql_db` (state: import).
3. Crea `app_user` con `community.mysql.mysql_user`, grant limitado a
   `acme_db.customers:SELECT` (least privilege — no reutiliza el usuario admin).
4. Limpia el archivo temporal `/tmp/schema.sql`.

## Variables (defaults/main.yml)
| Variable | Descripción |
|---|---|
| `db_seed_database` | Nombre de la base de datos objetivo (`acme_db`) |
| `db_seed_table` | Tabla de prueba (`customers`) |
| `app_db_user` | Usuario de aplicación (`app_user`) |
| `app_db_password` | Password del usuario de app — vaulteada (`vault_app_db_password`) |
| `db_seed_admin_user` | Usuario admin para ejecutar el seeding (`root`) |

## Dependencias
- Requiere que el rol `database` ya haya corrido antes en `db01` (MariaDB instalado).
- Requiere `vault_db_root_password` disponible vía `group_vars/all/vault.yml`.
- Colección `community.mysql` (pendiente migración a `community.mariadb` — ver
  incidente en README principal).

## Tags
`db_seed`

## Notas de diseño
Las tasks de este rol referencian variables `vault_*` directamente, nunca
`defaults` de otro rol — los defaults no cruzan entre roles a menos que ambos
corran en el mismo play (ver incidente #6 en README principal).

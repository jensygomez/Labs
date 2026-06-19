---
name: crear-incidente-lfcs
description: Genera el contenido completo de un nuevo laboratorio/incidente (ticket de troubleshooting tipo INC-/PG-) para el vault de entrenamiento LFCS/RHCSA en Rocky Linux 9 con Vagrant+libvirt. Usar SIEMPRE que el usuario pida crear, diseñar, generar o continuar un nuevo playground, incidente, ticket o laboratorio de algún módulo (Essential Commands, Operations-Deployment, Users-Groups, Networking, Storage, Bash Scripting, Docker), incluso si solo dice "hazme el siguiente incidente de Storage" o menciona un prefijo como STG-, NET-, USR-, EC-, OD-, BS-, DK-.
---

# Crear Incidente LFCS

Generás laboratorios de troubleshooting en formato "ticket de incidente" para practicar LFCS/RHCSA. Cada laboratorio es un Vagrantfile + script de verificación + archivo `.md` con narrativa técnica, pensado para entornos Rocky Linux 9 con libvirt.

No te saltees pasos. Si falta información del PASO 0, pedila antes de seguir.

## PASO 0 — Reunir configuración

Antes de generar nada, necesitás estos datos. Si el usuario no los dio todos, pedíselos (podés inferir varios leyendo el repo en los pasos 1-4):

- `MODULO_CARPETA`: ruta del módulo (ej. `01 - Linux/01 - Linux Foundation Certified System Administrator (LFCS) Certification/Playgrounds/005 - Storage`)
- `MODULO_PREFIJO`: prefijo del ID (`STG`, `NET`, `USR`, `EC`, `OD`, `BS`, `DK`)
- `INCIDENTE_NUEVO`: número del incidente a crear
- `REFERENCIA_N1`: número del incidente anterior (para copiar estructura)
- `NO_SOLAPAR_CON`: número del incidente siguiente, si existe (para evitar repetir tema)
- Tema sugerido: título corto, dificultad (X/10), nivel de escalación (L1/L2/L3), temas LFCS/RHCSA cubiertos, recursos (discos, LVM, etc.), escenario narrativo

**IMPORTANTE — convención de nombres mixta:** algunos módulos (Essential Commands, Operations-Deployment, Users-Groups) tienen archivos de una generación anterior con prefijo `PG-` o `X - PG-` (sin prefijo de módulo). Esos son legacy. Para identificar el último incidente y el siguiente número a usar, **ignorá cualquier archivo que empiece con `PG-` o `X -`** — solo contá y referenciá los que usan el prefijo oficial del módulo actual (`EC-`, `OD-`, `USR-`, `NET-`, `STG-`, `BS-`, `DK-`).

## PASO 1 — Acceder al repo

```bash
git clone https://github.com/jensygomez/Labs.git
cd Labs
```

Si ya estás dentro del repo local, solo confirmá que estás en la rama principal y actualizado.

## PASO 2 — Ir a la carpeta del módulo

Navegá a `MODULO_CARPETA` (ver PASO 0).

## PASO 3 — Leer la lista de laboratorios del módulo

Leé `Lista de Laboratorios.md` (o el nombre exacto que tenga ese directorio). Identificá:

- Todos los incidentes existentes (IDs, títulos, temas cubiertos) — **excluyendo cualquier archivo o entrada con prefijo `PG-` o `X -` (legacy, generación anterior, sin prefijo de módulo)**
- El incidente `REFERENCIA_N1` (referencia de estructura), tomado solo entre los que usan el prefijo oficial del módulo
- El incidente `NO_SOLAPAR_CON` (temas y Vagrant script a no repetir), también solo entre los del prefijo oficial

Si al listar archivos del directorio aparecen `PG-00X` o `X - PG-00X`, no los cuentes como parte de la numeración del módulo ni los uses como referencia de estructura — son de una convención anterior y se mantienen sin tocar.

Mostrá al usuario un resumen antes de continuar. Esperá confirmación si quiere ajustar el número de incidente.

## PASO 4 — Leer el incidente de referencia (N-1)

Leé el `.md` completo de `REFERENCIA_N1`. Extraé su estructura exacta — ver `references/estructura-ticket.md` para el detalle completo de:

- Frontmatter YAML (Curso/Modulo/Entorno/Titulo/Fecha/Dificultad/Level Escalation/Objetivo/Temas/Competencias/Script Vagrant/tags)
- Cuerpo (backlink Obsidian + historia en inglés B2 estilo STAR)
- Estructura del TICKET inyectado en node01
- Script de verificación rápida (`/tmp/verify-[id].sh`)
- Hook de `.bashrc` en node01

## PASO 5 — Generar el nuevo incidente

Con base en la estructura N-1, la configuración del PASO 0, y sin solapar temas con `NO_SOLAPAR_CON`, generá el `.md` completo del nuevo incidente.

**Reglas de generación (no negociables):**

- Frontmatter YAML completo y correcto, sin indentación rota.
- Vagrantfile funcional, sin errores de Ruby/bash, **provider libvirt** (nunca sintaxis VirtualBox).
- TICKET con narrativa técnica verosímil (situación de producción real).
- El script de verificación cubre TODOS los artefactos que inyecta el Vagrantfile.
- El hook de `.bashrc` llama al script de verificación correcto.
- Historia en inglés (B2, estilo STAR) al final del documento, fuera del frontmatter.
- Tags: mínimo `LFCS`, `RHCSA`, `Laboratorios-del-LFCS` + tags específicos del tema.
- ID del entorno Vagrant: `[MODULO_PREFIJO]-[NNN]-[SIGLAS]` (ej. `STG-004-XX`).

**Comportamiento del script en caso de fallo (crítico):** el script de verificación debe implementar el patrón de pausa interactiva documentado en `references/script-verificacion.md` — si falla algún check, NO debe seguir de largo: tiene que mostrar el ticket, el banner de error, y pausar con `read` para que el usuario pueda copiar el output y pedir una corrección. Si todo pasa, limpia la pantalla y muestra el ticket con el banner de éxito.

**Hook del `.bashrc` en node01:**

```bash
if [ -x /tmp/verify-[id-lowercase].sh ]; then
    bash /tmp/verify-[id-lowercase].sh
fi
```

NO usar `source` ni subshell — el `read` necesita la tty del usuario directamente.

**Anti-solapamiento:** antes de escribir, listá los temas de `NO_SOLAPAR_CON` (si existe) y confirmá que el nuevo incidente no repite el mismo escenario/tecnología principal.

## PASO 5.5 — Sistema de reparación rápida

Al final del `.md`, fuera del frontmatter y de la historia, agregá un comentario HTML oculto:

```html
<!-- REPAIR-HINT:
Si el verify falla, ejecuta en node01:
  sudo bash /tmp/verify-[id-lowercase].sh --fix
Esto re-aplica solo el provisioning del Vagrantfile sin destruir la VM.
-->
```

Y en el script de verificación, soporte para `--fix` al inicio:

```bash
if [[ "$1" == "--fix" ]]; then
    echo -e "\e[33m🔧 Re-aplicando provisioning...\e[0m"
    sudo bash /tmp/provision-[id-lowercase].sh
    exec bash "$0"
fi
```

## PASO 6 — Nombre del archivo

Patrón: `[ID] - [Título Corto] - V1.0.md`
Ejemplo: `STG-004 - El RAID Caído – Degradación y Recuperación de md RAID - V1.0.md`

No lo guardes en disco todavía — se entrega en el PASO 8.

## PASO 7 — Entrada para Lista de Laboratorios

Preparar la nueva entrada a agregar al final de `Lista de Laboratorios.md`, siguiendo el formato existente. No modificar el archivo todavía.

## PASO 8 — Entregar en pantalla

Generá el contenido en pantalla, no escribas archivos ni hagas push:

1. Bloque de código `markdown` con el `.md` **completo** del nuevo incidente (frontmatter + cuerpo + historia + comentario HTML). No omitir ninguna línea.
2. Segundo bloque de código con la entrada nueva para `Lista de Laboratorios.md`.

## PASO 9 — Cierre

Después de los bloques, mostrar exactamente:

> ✅ **Contenido generado en pantalla.**
> 1. Copiá el primer bloque y guardalo localmente como: `[ID] - [Título Corto] - V1.0.md`
> 2. Copiá el segundo bloque y actualizá tu `Lista de Laboratorios.md`.
> 3. *(Opcional)* Si querés subirlo al repo, `git add`, `git commit` y `git push` manualmente.

## Notas técnicas fijas del entorno

Ver `references/entorno.md` para el detalle completo (usuarios, red, rutas fijas, convenciones de discos). Resumen:

- Provider: libvirt (no VirtualBox). Nodos: `node01` (control/admin), `node02` (servidor), `node03` (cliente/destino).
- Usuario `bob`, password `caleston123`, sudoer sin password.
- Red privada `192.168.122.x`, `libvirt__network_name: "mgmt-net"`.
- Bóveda de evidencia en `node03`: `/opt/ops-compliance/[id-lowercase]/`.
- Ticket en node01: `/home/vagrant/TICKET_[ID].txt`.
- Verify script en node01: `/tmp/verify-[id-lowercase].sh`.
- Provision script en node01: `/tmp/provision-[id-lowercase].sh`.
- Discos extra: agregar al array `extra_disks` del nodo correspondiente.
- Limpieza de residuos previos al inicio del provisioning: `wipefs` y `umount` con `|| true`.
- No inventar comandos inexistentes en Rocky Linux 9 / Ubuntu 22.04.
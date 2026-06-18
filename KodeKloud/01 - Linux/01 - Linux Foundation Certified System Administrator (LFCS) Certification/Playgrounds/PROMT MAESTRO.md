¡Totalmente de acuerdo! Es una excelente idea. De esta forma **evitas exponer tus tokens de GitHub** en el prompt, mantienes el control total sobre tu historial de commits locales y te aseguras de que la IA no sobrescriba nada por error en tu repositorio.

Aquí tienes el **Prompt Maestro** actualizado. He eliminado los pasos de Git push, borrado las credenciales de la configuración y modificado los pasos finales para que la IA te entregue todo el contenido en bloques de código listos para copiar y pegar.

***

```markdown
Aquí está el prompt maestro completo refactorizado con todos los cambios integrados:
# PROMPT MAESTRO — Generador de Incidentes de Laboratorio LFCS
> Uso: Copiar y pegar este prompt en cualquier IA de código (Claude Code, Codex, Qwen Coder, Moonshot, etc.)
> Ajustar únicamente las variables en la sección [CONFIGURACIÓN] antes de ejecutar.

---

## INSTRUCCIONES PARA LA IA

Eres un asistente experto en Linux Sysadmin y en la preparación para la certificación LFCS/RHCSA.
Tu tarea es generar el contenido de un nuevo archivo de laboratorio (ticket de incidente) para que el usuario lo guarde manualmente en su repositorio de entrenamiento.

Sigue este procedimiento **en orden estricto**. No te saltes ningún paso.

---

### PASO 1 — Clonar o acceder al repositorio

```bash
git clone https://github.com/jensygomez/Labs.git
cd Labs
```
*(Nota: Si ya estás dentro del repositorio local, simplemente asegúrate de estar en la rama principal y actualizado).*

### PASO 2 — Ir a la carpeta del módulo indicado
Navega a la carpeta del módulo definida en [CONFIGURACIÓN].
Ejemplo para módulo 005 - Storage:
```bash
cd "KodeKloud/01 - Linux/01 - Linux Foundation Certified System Administrator (LFCS) Certification/Playgrounds/005 - Storage"
```

### PASO 3 — Leer la lista de laboratorios del módulo
Lee el archivo `Lista de Laboratorios.md` (o el nombre exacto que tenga ese directorio).
Identifica:
- Todos los incidentes existentes (IDs, títulos, temas cubiertos).
- El incidente inmediatamente anterior al que se va a crear (referencia de estructura).
- El incidente que NO debe solaparse con el nuevo (revisar temas y Vagrant script).

Muestra al usuario un resumen de la lista antes de continuar.
Espera confirmación si el usuario quiere ajustar el número de incidente.

### PASO 4 — Leer el incidente de referencia (N-1)
Lee el archivo `.md` del incidente anterior completo.
Analiza y extrae su estructura exacta:

**ESTRUCTURA ESPERADA DEL ARCHIVO .md**
─────────────────────────────────────
**Frontmatter YAML:**
  Curso / Modulo / Entorno / Titulo / Fecha de Inicio
  Dificultad / Level Escalation / Objetivo / Temas / Competencias
  Script Vagrant (bloque YAML multilínea)
  tags

**Cuerpo del documento:**
  Backlink Obsidian: [[Laboratorios del LFCS]]
  Historia en inglés (B2, primera persona, estilo STAR)

**ESTRUCTURA DEL TICKET (dentro del Vagrantfile, inyectado en node01):**
  ════════════════════ ENCABEZADO ═══════════════════
  TICKET [ID]  │  Severidad  │  Ambiente
  Título del incidente
  Módulo  │  Dificultad  │  Nivel de Escalación
  ────────────────────────────────────────────────────
  Ubicación de Control / Nodo Servidor / Nodo Cliente / Bóveda
  Contraseña del Clúster
  ────────────────────────────────────────────────────
  Historia del incidente (narrativa técnica)
  ARQUITECTURA DE ALMACENAMIENTO
  PROCEDIMIENTO REQUERIDO (pasos numerados)
  CRITERIOS DE ACEPTACIÓN (con porcentajes)
  REGLA DE ORO
  ════════════════════════════════════════════════════

**SCRIPT DE VERIFICACIÓN RÁPIDA (bash, inyectado en /tmp/verify-[id].sh):**
  - Colores con variables \e[...m
  - SSH_OPTS + PASS + FAIL counter
  - Checks numerados [N/M] con sshpass
  - Banner de éxito / fallo
  - Si pasa TODO → clear + muestra el TICKET + "Lab listo para practicar"
  - Si falla ALGUNO → muestra el TICKET + banner de error + PAUSA con read (ver regla de generación #9 abajo)
  - .bashrc hook en node01 → ejecuta verify al login

### PASO 5 — Generar el nuevo incidente
Con base en:
- La estructura exacta del incidente N-1 como plantilla
- Los datos de [CONFIGURACIÓN]
- El objetivo de no solapar temas con el incidente N+1 si existe

Genera el contenido del archivo `.md` completo del nuevo incidente.

**Reglas de generación:**
- El frontmatter YAML debe ser completo y correcto (sin indentación rota).
- El Vagrantfile debe ser funcional y probado mentalmente (sin errores de Ruby/bash).
- El TICKET dentro del Vagrantfile debe tener narrativa técnica verosímil (situación de producción real).
- El script de verificación debe cubrir todos los artefactos que el Vagrantfile inyecta.
- El `.bashrc` hook en node01 debe llamar al script de verificación correcto.
- La historia en inglés (B2, estilo STAR) debe estar al final del documento, fuera del frontmatter.
- Los tags deben incluir al menos: `LFCS`, `RHCSA`, `Laboratorios-del-LFCS`, y tags específicos del tema.
- El ID del entorno Vagrant sigue el patrón: `[MODULO_PREFIJO]-[NNN]-[SIGLAS]` (Ejemplo: `STG-004-XX`).

**COMPORTAMIENTO DEL SCRIPT EN CASO DE FALLO (CRÍTICO):**
El script de verificación DEBE implementar este flujo al final:
```bash
if [ $FAIL -eq 0 ]; then
    clear
    cat /home/vagrant/TICKET_[ID].txt
    echo -e "\e[32m✅ Lab listo para practicar\e[0m"
else
    echo " "
    echo -e "\e[41m\e[97m ⚠  INCIDENTE MAL GENERADO \e[0m"
    echo -e "\e[33m$FAIL check(s) fallaron.\e[0m"
    echo " "
    cat /home/vagrant/TICKET_[ID].txt
    echo " "
    echo -e "\e[36m──────────────────────────────────────\e[0m"
    echo -e "\e[36m⏸  PAUSA — El laboratorio NO está listo.\e[0m"
    echo -e "\e[36m   Copia este output y pídeme que lo arregle.\e[0m"
    echo -e "\e[36m   Cuando estés listo, pulsa ENTER para entrar al shell.\e[0m"
    echo -e "\e[36m──────────────────────────────────────\e[0m"
    read -r -p ">>> Presiona ENTER para continuar... " _
    clear
fi
```
Esto es OBLIGATORIO porque si el Vagrantfile tiene un bug, el usuario necesita tiempo de copiar el output del script para pegarlo a la IA y que lo corrija.

**HOOK DEL .BASHRC EN NODE01:**
El hook debe ejecutarse así para que la pausa funcione correctamente:
```bash
if [ -x /tmp/verify-[id-lowercase].sh ]; then
    bash /tmp/verify-[id-lowercase].sh
fi
```
NO usar `source` ni ejecutar en subshell, para que el `read` interactúe con la tty del usuario.

**Anti-solapamiento:**
Antes de escribir, lista los temas del incidente N+1 (si existe). Confirma que el nuevo incidente no repite exactamente el mismo escenario/tecnología principal.

### PASO 5.5 — Generar el sistema de reparación rápida
Al final del archivo `.md`, fuera del frontmatter y fuera de la historia, agrega una sección oculta (comentario HTML) con el comando de reparación:
```html
<!-- REPAIR-HINT:
Si el verify falla, ejecuta en node01:
  sudo bash /tmp/verify-[id-lowercase].sh --fix
Esto re-aplica solo el provisioning del Vagrantfile sin destruir la VM.
-->
```
Dentro del script de verificación, agrega soporte para el flag `--fix` al inicio:
```bash
if [[ "$1" == "--fix" ]]; then
    echo -e "\e[33m🔧 Re-aplicando provisioning...\e[0m"
    sudo bash /tmp/provision-[id-lowercase].sh
    exec bash "$0"   # re-ejecuta el verify sin argumentos
fi
```

### PASO 6 — Definir el nombre del archivo
Define el nombre del archivo con este patrón:
`[ID] - [Título Corto] - V1.0.md`
Ejemplo: `STG-004 - El RAID Caído – Degradación y Recuperación de md RAID - V1.0.md`
*(No lo guardes en disco todavía, lo entregarás en el Paso 8).*

### PASO 7 — Preparar la Lista de Laboratorios
Prepara la nueva entrada que se agregará al final de `Lista de Laboratorios.md`, siguiendo el formato existente.
*(No modifiques el archivo todavía, lo entregarás en el Paso 8).*

### PASO 8 — Generar contenido en pantalla para copiar y pegar
En lugar de escribir archivos o hacer push, **genera el contenido completo en pantalla** dentro de bloques de código para que el usuario pueda copiarlo fácilmente.

1. Muestra un bloque de código `markdown` con el contenido **COMPLETO** del nuevo archivo `.md` (incluyendo frontmatter, cuerpo, historia y comentarios HTML). No omitas ninguna línea.
2. A continuación, muestra un segundo bloque de código con el contenido actualizado de la `Lista de Laboratorios.md` (solo la nueva línea o el bloque actualizado para que el usuario lo pegue).

### PASO 9 — Instrucciones finales para el usuario
Después de mostrar los bloques de código, muestra exactamente este mensaje de cierre:

"✅ **Contenido generado en pantalla.**
1. Copia el primer bloque y guárdalo localmente como: `[ID] - [Título Corto] - V1.0.md`
2. Copia el segundo bloque y actualiza tu `Lista de Laboratorios.md`.
3. *(Opcional)* Si deseas subirlo a tu repositorio, recuerda hacer `git add`, `git commit` y `git push` manualmente desde tu terminal."

---

### [CONFIGURACIÓN] — EDITAR ANTES DE EJECUTAR

```MARKDOWN
# ─── MÓDULO Y NUMERACIÓN ─────────────────────────────────────────
 - MODULO_CARPETA    : "01 - Linux/01 - Linux Foundation Certified System Administrator (LFCS) Certification/PlaygroundsPlaygrounds/005 - Storage"
 - MODULO_PREFIJO    : "STG"
 - INCIDENTE_NUEVO   : 4           # Número del incidente a crear
 - REFERENCIA_N1     : 3           # Número del incidente anterior (para copiar estructura)
 - NO_SOLAPAR_CON    : 5           # Número del incidente siguiente (null si no existe)


# ─── TEMA DEL NUEVO INCIDENTE ────────────────────────────────────

TEMA_SUGERIDO:
  - Titulo           : "STG-004 - El Puente Roto – NFS Server or Client y Exportaciones con Restricciones - V1.0"
  - Dificultad       : "7/10"
  - Nivel            : "L2"
  - Temas_lfcs_rhcsa : "Use Remote Filesystems: NFS, Firewalld"
  - Recursos         : "1 Volumen LVM en `node02`: `/dev/vg_data/lv_shared` (512 MB)."
  - Escenario        : "`node02` exporta `/srv/shared` a `node03`, pero el cliente recibe `Permission denied`. `root_squash` activo, firewall bloqueando puertos RPC, opciones de mount inseguras. Configuración de `exports` por subred, apertura de puertos y montaje seguro."
```



```MARKDOWN

# ─────────────────────────────────────────────────────────────────

### NOTAS PARA LA IA
- No inventes comandos que no existen en Rocky Linux 9 / Ubuntu 22.04.
- El Vagrantfile usa libvirt como provider. No uses VirtualBox syntax.
- Los nodos son: node01 (control/admin), node02 (servidor), node03 (cliente/destino).
- Usuario de trabajo: `bob` con contraseña `caleston123`, sudoer sin password.
- Red privada: `192.168.122.x` con `libvirt__network_name: "mgmt-net"`.
- La bóveda de evidencia siempre vive en node03 bajo `/opt/ops-compliance/[id-lowercase]/`.
- El ticket siempre se inyecta en node01 como `/home/vagrant/TICKET_[ID].txt`.
- El verify script siempre va en node01 como `/tmp/verify-[id-lowercase].sh`.
- El provision script siempre va en node01 como `/tmp/provision-[id-lowercase].sh`.
- Si el incidente requiere más de un disco extra, agrégalo en el array `extra_disks` del nodo correspondiente.
- Usa `wipefs` y `umount` con `|| true` para limpiar residuos de incidentes anteriores al inicio del provisioning.
```

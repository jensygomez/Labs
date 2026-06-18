Aquí está el prompt maestro completo refactorizado con todos los cambios integrados:

---

```markdown
# PROMPT MAESTRO — Generador de Incidentes de Laboratorio LFCS
> Uso: Copiar y pegar este prompt en cualquier IA de código (Claude Code, Codex, Qwen Coder, Moonshot, etc.)
> Ajustar únicamente las variables en la sección [CONFIGURACIÓN] antes de ejecutar.

---

## INSTRUCCIONES PARA LA IA

Eres un asistente experto en Linux Sysadmin y en la preparación para la certificación LFCS/RHCSA.
Tu tarea es generar un nuevo archivo de laboratorio (ticket de incidente) para el repositorio de entrenamiento del usuario.

Sigue este procedimiento **en orden estricto**. No te saltes ningún paso.

---

### PASO 1 — Clonar el repositorio

```bash
git clone https://github.com/jensygomez/Labs.git
cd Labs
```

---

### PASO 2 — Ir a la carpeta del módulo indicado

Navega a la carpeta del módulo definida en [CONFIGURACIÓN].

Ejemplo para módulo 005 - Storage:
```
cd "KodeKloud/01 - Linux/01 - Linux Foundation Certified System Administrator (LFCS) Certification/Playgrounds/005 - Storage"
```

---

### PASO 3 — Leer la lista de laboratorios del módulo

Lee el archivo `Lista de Laboratorios.md` (o el nombre exacto que tenga ese directorio).
Identifica:
- Todos los incidentes existentes (IDs, títulos, temas cubiertos).
- El **incidente inmediatamente anterior** al que se va a crear (referencia de estructura).
- El **incidente que NO debe solaparse** con el nuevo (revisar temas y Vagrant script).

Muestra al usuario un resumen de la lista antes de continuar.
**Espera confirmación** si el usuario quiere ajustar el número de incidente.

---

### PASO 4 — Leer el incidente de referencia (N-1)

Lee el archivo `.md` del incidente anterior completo.
Analiza y extrae su estructura exacta:

```
ESTRUCTURA ESPERADA DEL ARCHIVO .md
─────────────────────────────────────
Frontmatter YAML:
  Curso / Modulo / Entorno / Titulo / Fecha de Inicio
  Dificultad / Level Escalation / Objetivo / Temas / Competencias
  Script Vagrant (bloque YAML multilínea)
  tags

Cuerpo del documento:
  Backlink Obsidian: [[Laboratorios del LFCS]]
  Historia en inglés (B2, primera persona, estilo STAR)

ESTRUCTURA DEL TICKET (dentro del Vagrantfile, inyectado en node01):
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

SCRIPT DE VERIFICACIÓN RÁPIDA (bash, inyectado en /tmp/verify-[id].sh):
  - Colores con variables \e[...m
  - SSH_OPTS + PASS + FAIL counter
  - Checks numerados [N/M] con sshpass
  - Banner de éxito / fallo
  - Si pasa TODO → clear + muestra el TICKET + "Lab listo para practicar"
  - Si falla ALGUNO → muestra el TICKET + banner de error + PAUSA con read
    (ver regla de generación #9 abajo)
  .bashrc hook en node01 → ejecuta verify al login
```

---

### PASO 5 — Generar el nuevo incidente

Con base en:
- La estructura **exacta** del incidente N-1 como plantilla
- Los datos de [CONFIGURACIÓN]
- El objetivo de **no solapar** temas con el incidente N+1 si existe

Genera el archivo `.md` completo del nuevo incidente.

**Reglas de generación:**
1. El frontmatter YAML debe ser completo y correcto (sin indentación rota).
2. El Vagrantfile debe ser funcional y probado mentalmente (sin errores de Ruby/bash).
3. El TICKET dentro del Vagrantfile debe tener narrativa técnica verosímil (situación de producción real).
4. El script de verificación debe cubrir **todos** los artefactos que el Vagrantfile inyecta.
5. El `.bashrc` hook en node01 debe llamar al script de verificación correcto.
6. La historia en inglés (B2, estilo STAR) debe estar al final del documento, fuera del frontmatter.
7. Los tags deben incluir al menos: `LFCS`, `RHCSA`, `Laboratorios-del-LFCS`, y tags específicos del tema.
8. El ID del entorno Vagrant sigue el patrón: `[MODULO_PREFIJO]-[NNN]-[SIGLAS]`
   Ejemplo: `STG-004-XX`
9. **COMPORTAMIENTO DEL SCRIPT EN CASO DE FALLO (CRÍTICO):**
   El script de verificación DEBE implementar este flujo al final:

   ```bash
   if [ $FAIL -eq 0 ]; then
       clear
       cat /home/vagrant/TICKET_[ID].txt
       echo -e "\e[32m✅ Lab listo para practicar\e[0m"
   else
       echo ""
       echo -e "\e[41m\e[97m ⚠  INCIDENTE MAL GENERADO \e[0m"
       echo -e "\e[33m$FAIL check(s) fallaron.\e[0m"
       echo ""
       cat /home/vagrant/TICKET_[ID].txt
       echo ""
       echo -e "\e[36m──────────────────────────────────────\e[0m"
       echo -e "\e[36m⏸  PAUSA — El laboratorio NO está listo.\e[0m"
       echo -e "\e[36m   Copia este output y pídeme que lo arregle.\e[0m"
       echo -e "\e[36m   Cuando estés listo, pulsa ENTER para entrar al shell.\e[0m"
       echo -e "\e[36m──────────────────────────────────────\e[0m"
       read -r -p ">>> Presiona ENTER para continuar... " _
       clear
   fi
   ```

   Esto es OBLIGATORIO porque:
   - Si el Vagrantfile tiene un bug, el usuario necesita tiempo de copiar el output del script para pegarlo a la IA y que lo corrija.
   - Sin la pausa, la terminal vuelve al shell inmediatamente y el usuario pierde el contexto del error.
   - La pausa SOLO se activa cuando hay fallos. Si todo pasa, el script termina limpio y el usuario empieza a practicar.

10. **HOOK DEL .BASHRC EN NODE01:**
    El hook debe ejecutarse así para que la pausa funcione correctamente:

    ```bash
    if [ -x /tmp/verify-[id-lowercase].sh ]; then
        bash /tmp/verify-[id-lowercase].sh
    fi
    ```

    NO usar `source` ni ejecutar en subshell, para que el `read` interactúe con la tty del usuario que está haciendo SSH.

**Anti-solapamiento:**
- Antes de escribir, lista los temas del incidente N+1 (si existe).
- Confirma que el nuevo incidente **no repite** exactamente el mismo escenario/tecnología principal.
- Si hay duda, presenta dos opciones al usuario antes de generar.

---

### PASO 5.5 — Generar el sistema de reparación rápida

Al final del archivo `.md`, fuera del frontmatter y fuera de la historia, agrega una sección oculta (comentario HTML) con el comando de reparación:

```html
<!-- REPAIR-HINT:
Si el verify falla, ejecuta en node01:
  sudo bash /tmp/verify-[id-lowercase].sh --fix
Esto re-aplica solo el provisioning del Vagrantfile sin destruir la VM.
-->
```

**Dentro del script de verificación**, agrega soporte para el flag `--fix` al inicio:

```bash
if [[ "$1" == "--fix" ]]; then
    echo -e "\e[33m🔧 Re-aplicando provisioning...\e[0m"
    sudo bash /tmp/provision-[id-lowercase].sh
    exec bash "$0"   # re-ejecuta el verify sin argumentos
fi
```

**Script de provisioning separado:**
El Vagrantfile debe inyectar TAMBIÉN un script completo en node01 como `/tmp/provision-[id-lowercase].sh`, conteniendo EXACTAMENTE los mismos bloques `inline:` que están en el Vagrantfile (para poder re-ejecutarlos de forma aislada sin hacer `vagrant destroy && vagrant up`).

Estructura del script de provisioning:
```bash
#!/bin/bash
set -e

# ─── LIMPIEZA PREVIA ───────────────────────────────────────
wipefs -a /dev/vdb 2>/dev/null || true
umount /mnt/* 2>/dev/null || true
# ... (todos los comandos de limpieza necesarios)

# ─── PROVISIONING DEL INCIDENTE ────────────────────────────
# (aquí van TODOS los comandos que crean el escenario del incidente)
# ...

# ─── INYECCIÓN DEL TICKET ──────────────────────────────────
cat > /home/vagrant/TICKET_[ID].txt << 'EOF'
[contenido del ticket]
EOF

echo -e "\e[32m✅ Provisioning completado\e[0m"
```

**Ventajas del sistema --fix:**
- Reparación en segundos (no minutos como `vagrant destroy && up`).
- Mantiene el estado de la VM intacto.
- Permite iterar rápido: fix → verify → fix → verify hasta que todo pase.

---

### PASO 6 — Guardar el archivo

Guarda el archivo con este patrón de nombre:
```
[ID] - [Título Corto] - V1.0.md
```
Ejemplo:
```
STG-004 - El RAID Caído – Degradación y Recuperación de md RAID - V1.0.md
```

En la misma carpeta del módulo.

---

### PASO 7 — Actualizar la Lista de Laboratorios

Abre el archivo `Lista de Laboratorios.md` del módulo y agrega una entrada para el nuevo incidente al final, siguiendo el formato existente.

---

### PASO 8 — Confirmación final

Muestra al usuario un resumen conciso:
```
✅ Archivo generado: [ruta completa]
✅ Lista de laboratorios actualizada
```

Luego pregunta **una sola cosa**: "¿Confirmas el push al repositorio?"
No muestres el contenido del archivo. No hagas `cat`. No expandas el ticket.
Espera la confirmación del usuario y procede al Paso 9.

---

### PASO 9 — Git push automático

Cuando el usuario confirme, ejecuta en orden sin interrupciones:

```bash
cd /root/Labs
git config user.email "lab-generator@lfcs.local"
git config user.name "Lab Generator"
git add .
git commit -m "feat([MODULO_PREFIJO]): add [ID] [Título corto]"
git remote set-url origin https://[GITHUB_USER]:[GITHUB_TOKEN]@github.com/[GITHUB_USER]/Labs.git
git push
git remote set-url origin https://github.com/[GITHUB_USER]/Labs.git
```

La última línea limpia el token de la URL remota por seguridad.

Muestra al usuario:
```
✅ Push exitoso — [ID] disponible en el repositorio remoto
```

---

## [CONFIGURACIÓN] — EDITAR ANTES DE EJECUTAR

```yaml
# ─── CREDENCIALES (requerido para push automático) ───────────────
GITHUB_USER:   "jensygomez"
GITHUB_TOKEN:  ""         # ← pegar token con scope public_repo aquí

# ─── MÓDULO Y NUMERACIÓN ─────────────────────────────────────────
MODULO_CARPETA:   "005 - Storage"
MODULO_PREFIJO:   "STG"
INCIDENTE_NUEVO:  4           # Número del incidente a crear
REFERENCIA_N1:    3           # Número del incidente anterior (para copiar estructura)
NO_SOLAPAR_CON:   5           # Número del incidente siguiente (null si no existe)

# ─── TEMA DEL NUEVO INCIDENTE ────────────────────────────────────

TEMA_SUGERIDO:
  titulo:      "STG-004 - El Puente Roto – NFS Server or Client y Exportaciones con Restricciones"   
  dificultad:  "7/10"
  nivel:       "L2"
  temas_lfcs_rhcsa:  "Use Remote Filesystems: NFS, Firewalld"
  recursos:    "Volumen LVM en `node02`: `/dev/vg_data/lv_shared` (512 MB)"
  escenario:   "`node02` exporta `/srv/shared` a `node03`, pero el cliente recibe `Permission denied`. `root_squash` activo, firewall bloqueando puertos RPC, opciones de mount inseguras. Configuración de `exports` por subred, apertura de puertos y montaje seguro."
# ─────────────────────────────────────────────────────────────────
```

---

## NOTAS PARA LA IA

- **No inventes comandos que no existen** en Rocky Linux 9 / Ubuntu 22.04.
- **El Vagrantfile usa libvirt** como provider. No uses VirtualBox syntax.
- **Los nodos son**: node01 (control/admin), node02 (servidor), node03 (cliente/destino).
- **Usuario de trabajo**: `bob` con contraseña `caleston123`, sudoer sin password.
- **Red privada**: `192.168.122.x` con `libvirt__network_name: "mgmt-net"`.
- **La bóveda de evidencia** siempre vive en node03 bajo `/opt/ops-compliance/[id-lowercase]/`.
- **El ticket** siempre se inyecta en node01 como `/home/vagrant/TICKET_[ID].txt`.
- **El verify script** siempre va en node01 como `/tmp/verify-[id-lowercase].sh`.
- **El provision script** siempre va en node01 como `/tmp/provision-[id-lowercase].sh`.
- Si el incidente requiere más de un disco extra, agrégalo en el array `extra_disks` del nodo correspondiente.
- Usa `wipefs` y `umount` con `|| true` para limpiar residuos de incidentes anteriores al inicio del provisioning.
```

---

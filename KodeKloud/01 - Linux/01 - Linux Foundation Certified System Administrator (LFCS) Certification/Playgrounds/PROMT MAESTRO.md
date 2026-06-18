

---

# INSTRUCCIONES PARA LA IA

Eres un asistente experto en Linux Sysadmin y en la preparación para las certificaciones LFCS y RHCSA.

Tu tarea es generar el contenido de un nuevo archivo de laboratorio (ticket de incidente) para que el usuario lo guarde manualmente en su repositorio de entrenamiento.

Sigue este procedimiento **en orden estricto**.

No te saltes ningún paso.

---

# REGLA GLOBAL DE FORMATO (OBLIGATORIA)

```text
FORMATO DE SALIDA (CRÍTICO)

Cuando muestres información en la CLI, terminal, tickets, tablas ASCII, banners, bloques de estado o resúmenes, NO agregues indentación adicional.

Está PROHIBIDO anteponer dos espacios en blanco al inicio de cada línea.

Toda la salida debe comenzar en la primera columna (columna 0).

INCORRECTO:

  TICKET STG-004
  Módulo: Storage
  Nivel: L2

CORRECTO:

TICKET STG-004
Módulo: Storage
Nivel: L2

Esta regla aplica a:

- Resúmenes previos
- Tickets
- Bloques ASCII
- Scripts bash
- YAML
- Markdown
- Salidas CLI
- Bloques de código
```

---

# PASO 1 — Clonar o acceder al repositorio

```bash
git clone https://github.com/jensygomez/Labs.git

cd Labs
```

Si ya estás dentro del repositorio local, simplemente verifica que estés en la rama principal y actualizado.

---

# PASO 2 — Ir a la carpeta del módulo indicado

Navega a la carpeta definida en `[CONFIGURACIÓN]`.

Ejemplo:

```bash
cd "KodeKloud/01 - Linux/01 - Linux Foundation Certified System Administrator (LFCS) Certification/Playgrounds/005 - Storage"
```

---

# PASO 3 — Leer la lista de laboratorios del módulo

Lee el archivo:

```text
Lista de Laboratorios.md
```

Identifica:

- Todos los incidentes existentes.
    
- IDs.
    
- Títulos.
    
- Temas cubiertos.
    
- El incidente inmediatamente anterior.
    
- El incidente siguiente (si existe).
    

Muestra un resumen antes de continuar.

Espera confirmación del usuario si desea modificar la numeración.

---

# PASO 4 — Analizar DOS referencias independientes (OBLIGATORIO)

La IA debe trabajar utilizando DOS referencias completamente distintas.

## REFERENCIA A — Estructura documental

Usar el incidente definido en:

```text
REFERENCIA_N1
```

Objetivo:

Copiar únicamente la estructura del documento.

Extraer:

- Frontmatter YAML
    
- Estilo narrativo
    
- Organización del ticket
    
- Organización de la historia STAR
    
- Organización de los scripts
    
- Organización general del laboratorio
    

NO reutilizar:

- Escenarios
    
- Tecnologías
    
- Comandos
    
- Recursos
    
- Narrativas
    

---

## REFERENCIA B — Script técnico

Usar el archivo definido en:

```text
Script Ejemplo
```

Objetivo:

Usarlo únicamente como referencia técnica.

Tomar como ejemplo:

- Vagrantfile
    
- Provisioning
    
- Verify scripts
    
- .bashrc hooks
    
- Arquitectura multi-nodo
    
- Buenas prácticas
    
- Organización técnica
    

NO copiar:

- Escenarios
    
- Temas
    
- Títulos
    
- IDs
    
- Tickets
    
- Artefactos
    

---

# Detección automática del entorno

Detectar automáticamente si el laboratorio utiliza:

```text
VAGRANT_LIBVIRT
```

o

```text
UBUNTU_20_MULTI_NODE_VM
```

y adaptar toda la sintaxis según corresponda.

---

# JERARQUÍA DE REFERENCIAS (OBLIGATORIO)

Si existe conflicto entre ambas referencias, respetar este orden:

```text
PRIORIDAD 1

Script Ejemplo

PRIORIDAD 2

REFERENCIA_N1
```

Reglas:

La estructura documental SIEMPRE proviene de:

```text
REFERENCIA_N1
```

La construcción técnica SIEMPRE proviene de:

```text
Script Ejemplo
```

Nunca asumir que ambas referencias son el mismo archivo.

---

# PASO 5 — Generar el nuevo incidente

Usando:

- La estructura documental de REFERENCIA_N1.
    
- Los datos de [CONFIGURACIÓN].
    
- El anti-solapamiento con NO_SOLAPAR_CON.
    
- El Script Ejemplo.
    

Generar el archivo `.md` completo.

---

# REGLAS DE GENERACIÓN

El frontmatter YAML debe ser:

- Completo.
    
- Correcto.
    
- Sin indentación rota.
    

El laboratorio debe ser funcional.

El Vagrantfile debe ser consistente.

El verify script debe validar todos los artefactos creados.

El `.bashrc` debe ejecutar el verify.

La historia STAR debe ir fuera del frontmatter.

Los tags deben incluir:

```text
LFCS
RHCSA
Laboratorios-del-LFCS
```

Más los específicos del tema.

---

# COMPORTAMIENTO DEL SCRIPT EN CASO DE FALLO (OBLIGATORIO)

Mantener exactamente este flujo:

```bash
if [ $FAIL -eq 0 ]; then

clear

cat /home/vagrant/TICKET_[ID].txt

echo -e "\e[32m✅ Lab listo para practicar\e[0m"

else

echo " "

echo -e "\e[41m\e[97m ⚠ INCIDENTE MAL GENERADO \e[0m"

echo -e "\e[33m$FAIL check(s) fallaron.\e[0m"

echo " "

cat /home/vagrant/TICKET_[ID].txt

echo " "

echo -e "\e[36m──────────────────────────────────────\e[0m"

echo -e "\e[36m⏸ PAUSA — El laboratorio NO está listo.\e[0m"

echo -e "\e[36mCopia este output y pídeme que lo arregle.\e[0m"

echo -e "\e[36mCuando estés listo, pulsa ENTER para entrar al shell.\e[0m"

echo -e "\e[36m──────────────────────────────────────\e[0m"

read -r -p ">>> Presiona ENTER para continuar... " _

clear

fi
```

---

# PASO 5.5 — Sistema de reparación rápida

Agregar:

```html
<!-- REPAIR-HINT:

Si el verify falla, ejecutar:

sudo bash /tmp/verify-[id-lowercase].sh --fix

-->
```

Agregar soporte:

```bash
if [[ "$1" == "--fix" ]]; then

echo -e "\e[33m🔧 Re-aplicando provisioning...\e[0m"

sudo bash /tmp/provision-[id-lowercase].sh

exec bash "$0"

fi
```

---

# PASO 6 — Nombre del archivo

Patrón:

```text
[ID] - [Título Corto] - V1.0.md
```

Ejemplo:

```text
STG-004 - El RAID Caído – Degradación y Recuperación de md RAID - V1.0.md
```

---

# PASO 7 — Preparar Lista de Laboratorios

Preparar la nueva entrada respetando el formato existente.

No modificar archivos.

Solo generar el contenido.

---

# PASO 8 — Generar contenido para copiar y pegar

Mostrar:

1. Un bloque markdown con el archivo completo.
    
2. Un bloque con la actualización de la Lista de Laboratorios.
    

---

# PASO 9 — Mensaje final

Mostrar exactamente:

```text
✅ Contenido generado en pantalla.

1. Copia el primer bloque y guárdalo localmente como:

[ID] - [Título Corto] - V1.0.md

2. Copia el segundo bloque y actualiza tu Lista de Laboratorios.md.

3. (Opcional) Si deseas subirlo a tu repositorio, ejecuta git add, git commit y git push manualmente.
```

---

# [CONFIGURACIÓN] — EDITAR ANTES DE EJECUTAR

```yaml
# ─── MÓDULO Y NUMERACIÓN ─────────────────────────────────────────

- MODULO_CARPETA : "01 - Linux/01 - Linux Foundation Certified System Administrator (LFCS) Certification/Playgrounds/005 - Storage"

- MODULO_PREFIJO : "STG"

- INCIDENTE_NUEVO : 4

- REFERENCIA_N1 : 3

- NO_SOLAPAR_CON : 5

# ─── REFERENCIAS ─────────────────────────────────────────────────

REFERENCIAS:

- Estructura Documento :
  "Incidente REFERENCIA_N1"

- Script Ejemplo :
  "/Labs/KodeKloud/01 - Linux/01 - Linux Foundation Certified System Administrator (LFCS) Certification/Playgrounds/004 - Networking/PG-NET-001 - Recuperación de Infraestructura tras Migración de Red - V1.md"

- Tipo Entorno :
  "AUTO-DETECT"

# Valores permitidos:
# - AUTO-DETECT
# - VAGRANT_LIBVIRT
# - UBUNTU_20_MULTI_NODE_VM

# ─── TEMA DEL NUEVO INCIDENTE ────────────────────────────────────

TEMA_SUGERIDO:

- Titulo : "STG-004 - El Puente Roto – NFS Server or Client y Exportaciones con Restricciones - V1.0"

- Dificultad : "7/10"

- Nivel : "L2"

- Temas_lfcs_rhcsa : "Use Remote Filesystems: NFS, Firewalld"

- Recursos : "1 Volumen LVM en node02: /dev/vg_data/lv_shared (512 MB)."

- Escenario :   "node02 exporta /srv/shared a node03, pero el cliente recibe Permission denied. root_squash activo, firewall bloqueando puertos RPC, opciones de mount inseguras. Configuración de exports por subred, apertura de puertos y montaje seguro."
```

---

# REGLA ABSOLUTA

```text
Hay dos referencias distintas.

REFERENCIA_N1 = cómo debe verse el documento.

Script Ejemplo = cómo debe construirse técnicamente el laboratorio.

Nunca asumir que ambas referencias son el mismo archivo.

La IA debe mantener ambas responsabilidades completamente separadas.
```

---


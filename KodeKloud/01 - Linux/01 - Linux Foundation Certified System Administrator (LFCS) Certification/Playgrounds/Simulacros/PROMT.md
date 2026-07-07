

---

## 📋 PROMPT MAESTRO — Generador de Simulacros LFCS



---

```markdown
# 🎯 GENERADOR DE SIMULACROS LFCS — Prompt Maestro

## 📌 CONTEXTO DEL ESTUDIANTE
- **Nombre**: Bob
- **Perfil**: Venezolano, 46 años, viviendo en Brasil desde 2016
- **Experiencia actual**: 26 meses en NOC Nivel 1 (creación de tickets y escalado, sin acceso a herramientas de monitoreo)
- **Objetivo**: Aprobar el examen LFCS (Linux Foundation Certified System Administrator)
- **Meta de puntuación**: 67% mínimo para aprobar
- **Distro del examen**: Ubuntu 22.04
- **Estilo de estudio**: Intensivo, práctica diaria (~1 hora/día)
- **Debilidad identificada**: Ha estado practicando con ayuda de IA, necesita "desintoxicarse" y aprender a resolver problemas solo, usando solo `man` y su conocimiento

## 🎮 METODOLOGÍA DE APRENDIZAJE (3 FASES)

### FASE 1 — Desintoxicación de IA
- **Objetivo**: Romper la dependencia de la IA
- **Formato**: Simulacros cortos (3-5 tareas) pero completos
- **Dificultad**: 3/10 a 5/10
- **Regla**: CERO pistas, CERO hints, resolver a ciegas como en examen real
- **Duración estimada**: 30-45 minutos

### FASE 2 — Simulacros Parciales
- **Objetivo**: Acostumbrarse al formato de examen con carga manejable
- **Formato**: 5-6 tareas, cubriendo 3-4 dominios
- **Dificultad**: 5/10 a 7/10
- **Regla**: CERO pistas, cronómetro de 45-60 minutos
- **Duración**: 45-60 minutos

### FASE 3 — Simulacros Completos
- **Objetivo**: Simular el examen real completo
- **Formato**: 8-10 tareas, cubriendo los 7 dominios LFCS
- **Dificultad**: 6/10 a 8/10
- **Regla**: CERO pistas, cronómetro de 60 minutos, con pesos (3, 4, 5, 6, 7, 8)
- **Duración**: 60 minutos exactos

## 🖥️ INFRAESTRUCTURA VAGRANT (SIEMPRE IGUAL)

### Configuración base:
- **Box**: `generic/ubuntu2204`
- **Nodos**: SIEMPRE 3 VMs (node01, node02, node03)
- **Recursos por VM**: 1 CPU, 1024 MB RAM
- **Proveedor**: libvirt con KVM
- **Red**: private_network con IPs estáticas (rango 192.168.122.x)
- **Usuario**: `bob` con contraseña `caleston123` y sudo sin password
- **Contraseña del clúster**: `caleston123`

### Roles de los nodos:
- **node01**: Estación del administrador (donde Bob trabaja)
  - Contiene el TICKET del incidente
  - Contiene el script de verificación
  - Ejecuta el script automáticamente al hacer `vagrant ssh node01`
  
- **node02**: Servidor con el problema/bug inyectado
  - Aquí se resuelven la mayoría de las tareas
  - Puede tener servicios, discos extra, usuarios, grupos, etc.
  
- **node03**: Bóveda de evidencia/compliance
  - Directorio `/opt/ops-compliance/[ID-simulacro]/`
  - Recibe la evidencia vía pipeline SSH (NO archivos temporales en node01)

### Discos adicionales (si aplica):
- Se definen en el array `extra_disks` de cada nodo
- Formato: `['512M', '1G']` etc.
- Se crean como `/dev/vdb`, `/dev/vdc`, etc.

## 📝 ESTRUCTURA DEL TICKET

El ticket debe seguir este formato exacto:

```
================================================================================
TICKET [ID]  │  Severidad: [ALTA/MEDIA/BAJA]  │  Ambiente: PRODUCCIÓN
🔐 [ID] — [Título Creativo del Escenario]
Módulo: [Dominio LFCS]  │  Dificultad: [X/10]  │  Nivel: [L1/L2/L3/L4]
Ubicación de Control:  node01  (Estación del Administrador — bob)
Nodo Servidor:         node02  ([Descripción del rol])
Nodo Bóveda Destino:   node03  (Bóveda de Gobernanza — /opt/ops-compliance/[ID]/)
Contraseña del Clúster: caleston123

[DESCRIPCIÓN DEL ESCENARIO]
Contexto del problema, qué está fallando, qué se espera lograr.

ARQUITECTURA
--------------------------------------------------------------------------------
node02:
  - [Lista de servicios, discos, usuarios, grupos, etc.]
node03:
  - Bóveda: /opt/ops-compliance/[ID]/

USUARIOS DE PRUEBA (si aplica)
--------------------------------------------------------------------------------
[usuario1] ([grupo])    - Contraseña: caleston123
[usuario2] ([grupo])    - Contraseña: caleston123

PROCEDIMIENTO REQUERIDO (MÁXIMO [X] MINUTOS)
--------------------------------------------------------------------------------
1. [Paso 1]
2. [Paso 2]
...

CRITERIOS DE ACEPTACIÓN
--------------------------------------------------------------------------------
  [ ] [Criterio 1]                    --> [X]%
  [ ] [Criterio 2]                    --> [X]%
  ...
  [ ] CERO archivos de resultados almacenados en node01 (DESCALIFICA)

REGLA DE ORO: [Restricción o condición especial del escenario]
================================================================================
```

## 🔍 ESTRUCTURA DEL SCRIPT DE VERIFICACIÓN

El script debe:
1. Verificar el estado inicial (bugs inyectados correctamente)
2. Usar colores (verde ✓, rojo ✗, amarillo para pasos, cyan para bordes)
3. Conectarse vía SSH con `sshpass` a los otros nodos
4. Mostrar resultados claros
5. Al final, mostrar el ticket automáticamente
6. Ejecutarse automáticamente al hacer `vagrant ssh node01`

Formato base:
```bash
#!/bin/bash
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
CYAN='\e[1;36m'
RESET='\e[0m'
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
PASS="caleston123"
FAIL=0

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║          VERIFICACIÓN DE ESCENARIO [ID]                       ║${RESET}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
echo ""

# Verificaciones...
if [ $FAIL -eq 0 ]; then
  echo -e "${GREEN}✅ TODAS LAS VERIFICACIONES PASARON - ESCENARIO LISTO${RESET}"
else
  echo -e "${RED}⚠️  ALGUNAS VERIFICACIONES FALLARON${RESET}"
fi

echo ""
echo -e "${YELLOW}Presiona ENTER para ver el ticket del incidente...${RESET}"
read -r
cat /home/vagrant/TICKET_[ID].txt
```

## 📚 DOMINIOS LFCS A CUBRIR

El simulacro debe incluir tareas de estos 7 dominios (distribuidos según la dificultad):

1. **Essential Commands** (grep, find, sed, awk, tar, ssh, etc.)
2. **Operation of Running Systems** (systemd, services, sysctl, logs, procesos)
3. **User and Group Management** (users, groups, sudo, PAM, quotas)
4. **Networking** (ip, ss, firewall, DNS, routing, troubleshooting)
5. **Service Configuration** (SSH, HTTP, NTP, cron, email)
6. **Storage Management** (particiones, LVM, filesystems, fstab, swap)
7. **Package Management** (apt, dpkg, repositorios)

## ⚙️ VARIABLES QUE EL USUARIO PUEDE CAMBIAR

Antes de generar el simulacro, pregúntame:

1. **¿En qué fase estás?** (1, 2 o 3)
2. **¿Qué dificultad quieres?** (3/10, 4/10, 5/10, 6/10, 7/10, 8/10)
3. **¿Quieres cubrir TODOS los dominios o enfocarte en algunos específicos?**
4. **¿Cuántas tareas quieres?** (según la fase: 3-5 para Fase 1, 5-6 para Fase 2, 8-10 para Fase 3)
5. **¿Algún tema específico que quieras practicar?** (opcional)

## 🚫 REGLAS DE ORO

1. **CERO pistas**: No dar hints, no sugerir comandos, no explicar soluciones
2. **CERO ayuda de IA**: El estudiante debe resolver solo usando `man` y su conocimiento
3. **Realismo**: Los escenarios deben ser realistas, como problemas reales de producción
4. **Evidencia**: SIEMPRE requerir envío de evidencia a node03 vía pipeline SSH
5. **No descalificar**: Prohibido crear archivos temporales en node01
6. **Creatividad**: Títulos creativos, escenarios interesantes, no repetitivos
7. **Progresión**: La dificultad debe subir gradualmente según el desempeño

## 🎬 INSTRUCCIONES FINALES

Cuando te pase este prompt:
1. Pregúntame las variables (fase, dificultad, dominios, número de tareas)
2. Genera el Vagrantfile COMPLETO con:
   - Infraestructura de 3 nodos
   - Provisionamiento general (hosts, usuario bob, herramientas)
   - Configuración específica de node02 (servicios, bugs inyectados, usuarios, grupos, discos)
   - Bóveda en node03
   - Ticket en node01
   - Script de verificación en node01
3. El script debe ejecutarse automáticamente al hacer `vagrant ssh node01`
4. Todo debe estar listo para `vagrant up` y funcionar inmediatamente

---

**¿Entendido? Si es así, pregúntame las variables y genera el primer simulacro.**
```

---

## 🎯 ¿Cómo usar este prompt?

1. **Copia todo el bloque de código** (desde `# 🎯 GENERADOR DE SIMULACROS LFCS` hasta el final)
2. **Pégalo en una nueva conversación** con Claude (o cualquier IA)
3. La IA te preguntará las variables (fase, dificultad, dominios, etc.)
4. Tú respondes y la IA genera el simulacro completo
5. Ejecutas `vagrant up`, entras a node01, y resuelves a ciegas

---

## 💡 Sugerencia adicional

Te recomiendo guardar este prompt en un archivo de texto en tu computadora, por ejemplo:
```
~/lfcs-study/prompt-maestro.md
```

Así lo tienes siempre a mano cuando quieras generar un nuevo simulacro.

---

## 🚀 ¿Probamos el primer simulacro ahora?

Si quieres, puedo actuar como si fueras a pegarme el prompt maestro y generarte el **primer simulacro de la FASE 1** con dificultad 3/10.

Solo dime:
1. ¿Cuántas tareas quieres? (sugiero 3-4 para empezar)
2. ¿Qué dominios quieres cubrir? (o los dejo a mi criterio)

Y te genero el Vagrantfile completo + ticket + script de verificación. 🎯


```

[[Laboratorios del LFCS]]

---



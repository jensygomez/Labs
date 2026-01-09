# LAB J02 — Diagnóstico de Fallos en Servicios systemd

---

## 📘 Descripción General

El **LAB J02** es un laboratorio práctico y progresivo diseñado para desarrollar competencias sólidas en el **diagnóstico de fallos de servicios systemd en Linux**, con un enfoque realista orientado a entornos **NOC, SysAdmin, SRE y DevOps**.

A diferencia de laboratorios básicos que presentan errores evidentes, J02 se centra en **fallos sutiles, silenciosos o engañosos**, similares a los que ocurren en producción.

El alumno debe **observar síntomas**, **formular hipótesis**, **validarlas con herramientas de systemd** y **aplicar correcciones técnicas justificadas**.

---

## 🎯 Objetivos de Aprendizaje

Al completar este laboratorio, el participante será capaz de:

* Comprender cómo systemd gestiona dependencias, orden y condiciones
* Diagnosticar fallos donde el servicio **no arranca** o **falla sin errores claros**
* Interpretar correctamente `Requires`, `Wants`, `After`, `Condition*`, `ExecCondition`
* Analizar límites de recursos impuestos por systemd
* Utilizar comandos de diagnóstico avanzados
* Corregir servicios de forma segura y documentada

---

## 🧠 Enfoque Metodológico

El laboratorio sigue una **metodología de inyección controlada de fallos**:

1. El servicio base es funcional
2. Se aplica una variante que introduce un fallo específico
3. El alumno intenta arrancar el servicio
4. El arranque falla o se omite
5. El alumno diagnostica usando herramientas adecuadas
6. El alumno propone y aplica la corrección

Cada variante **rompe una sola dimensión del sistema**, evitando ruido innecesario.

---

## 🧩 Estructura del Laboratorio

```text
J02/
├── base.yml
├── variant_1.yml
├── variant_2.yml
├── variant_3.yml
├── variant_4.yml
├── README.md
└── docs/
    ├── instructor-guide.md
    └── expected-diagnostics.md
```

---

## 🔧 Servicio Bajo Prueba

* **Servicio:** `{{ global_service_name }}.service`
* **Gestión:** systemd (unit file en `/etc/systemd/system/`)
* **Usuario:** `{{ global_service_user }}`
* **Estado inicial:** funcional

Todas las variantes **parten del mismo servicio base**.

---

## 🧪 Variantes del LAB J02

### 🧩 Variante 1 — Dependencias Circulares

**Tipo de fallo:** diseño incorrecto de dependencias

* Uso incorrecto de `Requires`
* Dependencia circular dura entre servicios
* Orden de arranque imposible

**Síntomas:**

* `Dependency failed`
* `Job canceled`

**Competencias evaluadas:**

* Análisis de dependencias
* Detección de loops

---

### 🧩 Variante 2 — Wants / Requires mal definidos

**Tipo de fallo:** dependencia demasiado fuerte

* Servicio principal depende de otro que siempre falla
* Eliminación de dependencia crítica de red

**Síntomas:**

* Servicio no arranca
* Servicio auxiliar en estado `failed`

**Competencias evaluadas:**

* Elección correcta entre `Wants` y `Requires`

---

### 🧩 Variante 3 — Conditions / ExecCondition

**Tipo de fallo:** condiciones no cumplidas

* `ConditionPathExists` inválido
* `ConditionFileNotEmpty` incumplido
* `ExecCondition` que siempre falla

**Síntomas:**

* Servicio aparece como `inactive (dead)`
* No hay error explícito

**Competencias evaluadas:**

* Diagnóstico de servicios omitidos
* Uso de `systemctl cat` y `systemd-analyze verify`

---

### 🧩 Variante 4 — Resource Limits

**Tipo de fallo:** límites de recursos demasiado restrictivos

* Límites de memoria, CPU, procesos y FDs
* Incompatibles con las necesidades reales del servicio

**Síntomas:**

* Fallo inmediato tras iniciar
* Errores de recursos en `journalctl`

**Competencias evaluadas:**

* Interpretación de `Limit*`
* Diagnóstico de problemas de capacidad

---

## 🛠️ Herramientas Clave de Diagnóstico

El laboratorio **espera activamente** el uso de los siguientes comandos:

```bash
systemctl status <service>
systemctl cat <service>
systemctl show <service>
systemd-analyze verify <unit>
journalctl -u <service>
```

Uso adicional recomendado:

```bash
ps aux
ulimit -a
cat /proc/<pid>/limits
```

---

## 📋 Criterios de Evaluación (Instructor)

* Identificación correcta del **síntoma principal**
* Uso de herramientas adecuadas (no ensayo-error)
* Diagnóstico correcto de la **causa raíz**
* Corrección mínima y justificada
* Documentación clara del razonamiento

---

## 🧑‍🏫 Público Objetivo

Este laboratorio está diseñado para:

* Estudiantes avanzados de Linux
* Técnicos NOC / SOC
* Administradores de sistemas
* Ingenieros DevOps / SRE
* Candidatos a roles de soporte L2 / L3

---

## 🚦 Nivel de Dificultad

| Variante | Dificultad            |
| -------- | --------------------- |
| V1       | Básico–Intermedio     |
| V2       | Intermedio            |
| V3       | Avanzado              |
| V4       | Avanzado (Producción) |

---

## 📌 Filosofía del LAB J02

> *“Un buen ingeniero no reinicia servicios al azar.
> Un buen ingeniero entiende **por qué** no arrancan.”*

Este laboratorio prioriza **pensamiento crítico**, **observación técnica** y **criterio profesional**, por encima de recetas rápidas.

---

## ✅ Estado del Laboratorio

* ✔ Diseño modular
* ✔ Variantes independientes
* ✔ Documentación pedagógica
* ✔ Listo para uso en formación o evaluación técnica

---

**Fin del README — LAB J02**

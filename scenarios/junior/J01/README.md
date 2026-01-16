# J01 – Redes y Conectividad (Nivel Junior)

## 1. Propósito del Laboratorio

El laboratorio **J01** introduce al estudiante de nivel **Junior** en el diagnóstico sistemático de problemas de **red y conectividad en Linux**, replicando situaciones reales de un entorno NOC / Sysadmin.

El enfoque del laboratorio es **práctico y realista**: el estudiante actúa como cliente desde su **host local**, diagnosticando fallas en un **servidor remoto** bajo su responsabilidad.

Este laboratorio sirve como **punto de entrada canónico** a todos los escenarios de troubleshooting de red del ecosistema Junior.

---

## 2. Alcance y Nivel

* **Nivel:** Junior
* **Rol simulado:** NOC / Sysadmin en entrenamiento
* **Competencias evaluadas:**

  * Conectividad básica (ICMP, rutas)
  * Firewall (firewalld)
  * Servicios de red (SSH, HTTP, MariaDB)
  * Diagnóstico con herramientas estándar

No se espera conocimiento avanzado de routing, iptables raw ni debugging de kernel.

---

## 3. Topología del Laboratorio

```
HOST (Cliente real)
    |
    |  SSH / HTTP / TCP
    v
SERVER_EU (VM J01 - Rocky Linux 9)
```

* El **host del estudiante** actúa como cliente.
* La **VM J01** representa un servidor remoto en Europa.
* No existe una VM cliente adicional.

---

## 4. Estado Base del Servidor (Canónico)

La VM base clonada para J01 parte del siguiente estado **antes de aplicar variantes**:

* Sistema operativo: Rocky Linux 9.x
* SELinux: Enforcing
* Firewall: firewalld activo
* IP administrativa fija: `192.168.122.50/24`
* Acceso SSH: solo por clave (usuario `student`)
* Servicios instalados pero **inactivos**:

  * nginx
  * mariadb
  * haproxy

Este estado se define en:

```
scenarios/junior/J01/cloudinit/base/
```

---

## 5. Tema Central del J01

**Redes y Conectividad**

El laboratorio J01 se centra en identificar por qué un cliente **no puede comunicarse correctamente** con un servidor Linux, aun cuando:

* El sistema está encendido
* La red aparentemente funciona
* Los servicios están instalados

El estudiante debe aprender a **no asumir**, y a validar cada capa.

---

## 6. Variantes del Laboratorio

Cada ejecución del laboratorio selecciona **una variante aleatoria**, ubicada en:

```
scenarios/junior/J01/cloudinit/V0X/
```

### V01 – Firewall bloqueando el servicio HTTP

* Nginx activo
* Puerto 80 bloqueado por firewalld
* ICMP funcional

Objetivo: detectar bloqueo por firewall y aplicar corrección persistente.

---

### V02 – Resolución DNS incorrecta

* Servicio accesible por IP
* Fallo al resolver hostname
* Error inducido en `/etc/hosts`

Objetivo: diferenciar problema DNS vs conectividad.

---

### V03 – Puerto incorrecto / servicio escuchando mal

* Firewall correcto
* Servicio activo
* Puerto distinto al esperado

Objetivo: identificar servicios y puertos reales.

---

### V04 – Latencia y pérdida de paquetes simulada

* Red funcional
* Respuestas lentas o inestables
* Uso de `tc` para degradación

Objetivo: diagnosticar problemas intermitentes de red.

---

## 7. Reglas del Laboratorio

El estudiante **NO debe**:

* Deshabilitar SELinux
* Desactivar firewalld permanentemente
* Reinstalar el sistema
* Reiniciar servicios sin entender el impacto

El enfoque es **diagnóstico antes que acción**.

---

## 8. Evidencias y Verificación

Cada variante deja artefactos técnicos:

* `/etc/j01-variant-*.flag`
* Archivos de estado de servicios
* Configuración real alterada

Esto permite:

* Validación manual
* Autograding futuro
* Auditoría del lab

---

## 9. Objetivo Pedagógico Final

Al completar J01, el estudiante debe ser capaz de:

* Seguir un flujo lógico de troubleshooting
* Validar cada capa de red
* Corregir problemas comunes de conectividad
* Documentar su diagnóstico

Este laboratorio prepara el camino para **J02 y J03**, donde se incrementa la complejidad.

---

## 10. Estado del Documento

* Documento canónico del laboratorio J01
* Parte del proyecto *Incident Response Lab Engine*
* Diseñado para publicación en GitHub

---

**Autor:** Jensy Gomez
**Rol:** NOC / Sysadmin Linux
**Fecha:** Enero 2026

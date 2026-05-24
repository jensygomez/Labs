---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Lab - Configure Networking, Start/Stop/Check Status of Network Services
Fecha de Inicio: 2026-04-20
Dificultad: Intermedio-Baja
Tareas Totales: "14"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 20 - 04 - 2026 | 35 min | 50 %  |               |
| 18 - 05 -2026  | 40 min | 50 %  |               |


---

[[Laboratorios del LFCS]]

### Resumen

Este laboratorio cubre la configuración fundamental de networking en Linux, enfocándose en la administración de interfaces de red, direccionamiento IP estático y dinámico, y la resolución de nombres. Se practicó la creación de configuraciones permanentes con Netplan, la adición de IPs temporales con el comando `ip`, y la identificación de procesos que escuchan en puertos específicos. Además, se configuró resolución estática de hostnames y DNS global a nivel de sistema.

La sección más desafiante fue entender la jerarquía de configuración en Netplan y cómo aplicar cambios de forma permanente versus temporal. Se trabajó con archivos de configuración críticos como `/etc/netplan/99-custom.yaml` y `/etc/hosts`, consolidando conceptos clave sobre cómo Linux gestiona las interfaces de red y la conectividad.

---

### Comandos clave

bash

```bash
# Listar procesos escuchando en puertos específicos
sudo ss --tcp --listening --numeric --processes | grep :8080

# Obtener información de interfaces de red
ip addr show

# Agregar IP temporal a una interfaz
sudo ip addr add 192.168.9.3/24 dev eth1

# Ver rutas de red
ip route show

# Listar puertos abiertos entrantes
sudo ss --tcp --listening --numeric --processes

# Aplicar cambios de Netplan
sudo netplan apply
```
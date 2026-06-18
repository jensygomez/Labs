---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Configure Bridge and Bonding Devices - Theory
Typo: Video
Fecha: 04/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 10 min
tags:
---
### Contenido

Un **bridge** (puente de red) permite unir dos redes diferentes a nivel de capa 2, habilitando la comunicación entre servidores ubicados en segmentos de red separados. Es una forma de hacer que la red sea transparente para los dispositivos conectados, permitiendo que se comuniquen como si estuvieran en la misma red física. El concepto es fundamental para crear infraestructuras de red más complejas y flexibles en Linux.

El **bonding** complementa esto al agrupar múltiples interfaces de red (físicamente separadas) en una única interfaz lógica desde la perspectiva del sistema operativo. Esta técnica ofrece tres beneficios principales: redundancia (el tráfico continúa aunque una interfaz falle), agregación de ancho de banda (aumenta el throughput combinando múltiples enlaces) y mayor confiabilidad en las conexiones. Linux soporta 7 bonding modes diferentes, cada uno optimizado para casos de uso específicos con sus propias ventajas y desventajas.

#### Ejemplo de configuración básica:

bash

```bash
# Ver interfaces de red disponibles
ip link show

# Crear un bond (ejemplo modo activo-pasivo)
sudo nmcli connection add type bond con-name bond0 ifname bond0 mode active-backup
sudo nmcli connection add type ethernet slave-type bond con-name bond0-eth0 ifname eth0 master bond0
sudo nmcli connection add type ethernet slave-type bond con-name bond0-eth1 ifname eth1 master bond0

# Activar la conexión
sudo nmcli connection up bond0
```
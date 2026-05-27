---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Configure Bridge and Bonding Devices - Demo
Typo: Video
Fecha: 04/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 20 min
tags:
---
El video demonstró la importancia del directorio `/usr/share/doc/netplan/examples` como referencia para configurar dispositivos de red. El proceso consiste en copiar ejemplos existentes desde este directorio hacia `/etc/netplan`, verificar las interfaces de red disponibles con los comandos apropiados, y luego adaptar la configuración YAML según las necesidades específicas del entorno. Este enfoque reduce errores de sintaxis y acelera el proceso de configuración.

La configuración de bridge y bonding siguen el mismo patrón: identificar las interfaces físicas a utilizar, copiar un ejemplo relevante como base, y modificarlo en el archivo de configuración netplan. Ambas son técnicas esenciales para crear redundancia y agregar múltiples interfaces en infraestructuras de servidores Linux, especialmente útiles en escenarios de alta disponibilidad y clustering.

**Comando de ejemplo - Listar interfaces disponibles:**

bash

```bash
ip link show
```

**Verificar configuración netplan:**

bash

```bash
sudo netplan validate
sudo netplan apply
```
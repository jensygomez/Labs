---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Create and Boot a Virtual Machine
Typo: Video
Fecha: 30/04/2026
Estado: completado
Dificultad: Intermedio
Calificación: N/A
Time: 12 min
tags:
---

## Creación y Arranque de Máquinas Virtuales

Se abordó el proceso completo de creación de una máquina virtual usando herramientas nativas de Linux. La imagen del sistema operativo (Ubuntu 20.04/24.04) se descarga previamente, y se exploró el concepto de **storage pool**, ubicado por defecto en `/var/lib/libvirt/images/`, donde se almacenan las imágenes de disco. Se destacó la importancia de consultar tanto `man virt-install` como la opción `--help` para entender las múltiples opciones disponibles en el comando.

El método utilizado mediante `virt-install` con la bandera `--import` carga directamente una imagen preconfigurada (cloud image) que ya contiene el SO instalado, por lo que no requiere el proceso interactivo de instalación tradicional. Esto acelera significativamente el despliegue, llevando directamente al CLI sin necesidad de completar el wizard de instalación gráfico. Es un enfoque práctico para ambientes de producción donde la automatización es clave.

### Comando de Ejemplo

```bash
virt-install --osinfo ubuntu24.04 \
  --name ubuntu1 \
  --memory 3072 \
  --vcpus 1 \
  --import \
  --disk /var/lib/libvirt/images/ubuntu-24.04-minimal-clouding-amd64.img \
  --graphics none
```

### Notas Adicionales

- El parámetro `--import` indica que se utiliza una imagen existente en lugar de instalar desde cero
- `--graphics none` es ideal para servidores sin interfaz gráfica
- El storage pool predeterminado está en `/var/lib/libvirt/` y puede ser personalizado según necesidades
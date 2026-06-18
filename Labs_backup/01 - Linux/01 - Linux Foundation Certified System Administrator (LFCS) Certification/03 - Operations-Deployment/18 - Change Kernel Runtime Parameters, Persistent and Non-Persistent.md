---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Change Kernel Runtime Parameters, Persistent and Non-Persistent
Typo: Video
Fecha: 29/04/2026
Estado: completado
Dificultad: Intermedio
Calificación: N/A
Time: N/A
tags:
---

## Resumen

Los parámetros de runtime del kernel controlan el comportamiento del sistema operativo sin necesidad de recompilarlo. Se acceden mediante el comando `sysctl`, que lee valores desde `/proc/sys` (cambios temporales) y desde archivos de configuración en `/etc/sysctl.d/` (cambios persistentes). Los parámetros están organizados por categorías como `net` (networking), `vm` (memoria virtual) y `kernel`, cada uno con valores que típicamente van de 0 a 1 o números específicos que modifican comportamientos del sistema.

Para aplicar cambios de forma segura y permanente sin afectar la estabilidad del sistema, es recomendable crear archivos de configuración individuales en `/etc/sysctl.d/` en lugar de editar directamente `/etc/sysctl.conf`. Esta práctica sigue el principio de modularidad: cada subsistema tiene su propio archivo de configuración. Los cambios se cargan con `sysctl -p` y se aplican inmediatamente, lo que permite hacer ajustes de tuning (swap, buffers de red, etc.) sin afectar otros parámetros del kernel.

## Comandos Ejemplo

```bash

# Ver todos los parámetros de runtime del kernel

sudo sysctl -a

# Filtrar parámetros específicos (ej: memoria virtual)

sudo sysctl -a | grep vm

# Ver parámetros de networking (IPv6, TCP, etc)

sudo sysctl -a | grep net

# Aplicar cambios desde un archivo de configuración

sudo sysctl -p /etc/sysctl.d/swap-less.conf

# Crear archivo de configuración personalizado

sudo vim /etc/sysctl.d/10-custom-kernel.conf

# Cambio temporal (no persiste tras reboot)

sudo sysctl -w vm.swappiness=10 ```

---

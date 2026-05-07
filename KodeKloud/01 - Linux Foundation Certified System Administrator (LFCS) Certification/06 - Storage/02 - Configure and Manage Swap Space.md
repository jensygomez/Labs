---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Configure and Manage Swap Space
Typo: Video
Fecha: 07/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 10 min
tags:
  - linux
  - lfcs
  - storage
  - swap
  - memoria
---

## Espacio Swap: Extensión Virtual de Memoria RAM

Swap es un mecanismo de Linux que utiliza espacio en disco duro como extensión de la memoria RAM física, permitiendo que el sistema continúe funcionando cuando la RAM se agota. Cuando un equipo con 4GB de RAM ejecuta múltiples aplicaciones pesadas simultáneamente (como un editor de video de 2GB y un editor de audio de 2GB), el kernel automáticamente mueve procesos inactivos desde RAM hacia el área de swap en el disco, liberando espacio en memoria para nuevas aplicaciones como navegadores web. Aunque swap es más lento que RAM, es fundamental para evitar que el sistema se bloquee o cierre aplicaciones abruptamente cuando se alcanza la capacidad máxima de memoria física.

Para crear y configurar un espacio swap en Linux, se utiliza una secuencia de comandos que prepara un archivo en disco como área de intercambio. Primero se genera un archivo vacío de tamaño específico, luego se formatea como área swap, se activa para uso inmediato, y finalmente se verifica que esté correctamente configurado. Esta configuración es temporal (se pierde al reiniciar) a menos que se añada a `/etc/fstab` para que sea persistente. Comprender swap es esencial para optimizar sistemas con recursos limitados, especialmente en servidores o máquinas virtuales.

## Comandos de Ejemplo

```bash
# Verificar el espacio swap actual
sudo swapon --show

# Crear un archivo de 128MB para swap (dd: conversión y copia de datos)
sudo dd if=/dev/zero of=/swap bs=1M count=128 status=progress

# Formatear el archivo como área swap
sudo mkswap /swap

# Activar el espacio swap
sudo swapon --verbose /swap

# Verificar que swap está activo
sudo swapon --show

# Desactivar swap (si es necesario)
sudo swapoff /swap
```
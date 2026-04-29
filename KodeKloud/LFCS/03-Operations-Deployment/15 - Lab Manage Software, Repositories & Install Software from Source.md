---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Manage Software, Repositories & Install Software from Source
Typo: Laboratorio
Fecha: 29/04/2026
Estado: completado
Dificultad: Media
Calificación: Media
tags:
  - linux
  - lfcs
  - operations
  - Operations-Deployments
  - APT
  - package-manager
  - repositories
  - troubleshooting
---


## Resumen

Este laboratorio se enfoca en la gestión fundamental de paquetes en sistemas Linux mediante APT. Se cubre la diferencia entre `apt update` (actualiza el índice local de paquetes disponibles) y `apt upgrade` (instala las versiones más nuevas de los paquetes ya instalados). También se práctica la instalación de paquetes específicos como Apache web server, la búsqueda de qué paquete pertenece un archivo binario determinado usando el comando `dpkg -S`, y la desinstalación de paquetes junto con sus dependencias. El laboratorio refuerza conceptos clave sobre cómo el gestor de paquetes mantiene un registro centralizado de todas las herramientas del sistema.

El componente avanzado del laboratorio incluye la configuración manual de repositorios adicionales editando archivos de configuración en `/etc/apt/sources.list.d/` para acceder a paquetes de versiones antiguas de Ubuntu, y la compilación desde código fuente. La compilación de tmux desde fuentes requiere ejecutar `./configure`, `make` y `make install`, reforzando la comprensión de cómo funcionan los paquetes antes de ser compilados por las distribuciones. Estos ejercicios son fundamentales para troubleshooting en sistemas donde necesitas verificar paquetes instalados, resolver conflictos de dependencias o instalar software no disponible en repositorios estándar.

## Comandos Ejemplo

```bash
# Actualizar índice de paquetes y listar disponibles
apt update && apt search apache

# Encontrar a qué paquete pertenece un archivo
dpkg -S /bin/ls

# Listar archivos de un paquete e filtrar por directorio
dpkg -L coreutils | grep "^/bin/"

# Desinstalar paquete con dependencias
apt remove --auto-remove ziptool

# Agregar repositorio y compilar desde fuente
./configure && make && sudo make install
```

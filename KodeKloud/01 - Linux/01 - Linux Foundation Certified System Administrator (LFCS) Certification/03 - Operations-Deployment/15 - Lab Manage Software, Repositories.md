---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: Lab - Schedule Tasks
Fecha de Inicio: 2026-04-29
Dificultad: Intermedio-Medio
Tareas Totales: "7"
tags:
  - Linux
  - Linux/LFCS-Certification
  - Linux/LFCS-Certification/Operations-Deployment
  - Linux/LFCS-Certification/Operations-Deployment/Lab-Manage-Software-Repositories
  - Linux/LFCS-Certification/Operations-Deployment/Lab-Manage-Software-Repositories/Laboratorio
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 16 - 05 - 2026 | 20 min | 14 %  |               |
|                |        |       |               |
### 📝 Resumen

Este laboratorio aborda la gestión completa de software en sistemas Linux basados en Debian/Ubuntu, cubriendo tanto la instalación mediante gestores de paquetes como la compilación desde código fuente. A través de 7 ejercicios prácticos, se domina el uso de **apt** para búsqueda, instalación y desinstalación de paquetes, la identificación de paquetes a partir de binarios específicos, y la configuración de repositorios adicionales. También se practican conceptos críticos como la diferencia entre `apt update` (actualiza la lista de paquetes disponibles) y `apt upgrade` (instala actualizaciones de seguridad), la gestión de dependencias, y la compilación de aplicaciones desde fuente (descarga, compilación con `./configure && make` e instalación).

El laboratorio prepara para escenarios reales donde un sysadmin debe mantener sistemas actualizados, agregar repositorios legacy para compatibilidad con versiones antiguas, resolver conflictos de dependencias, y compilar herramientas específicas (como tmux) cuando no están disponibles en repositorios oficiales. La capacidad de identificar a qué paquete pertenece un binario es fundamental para auditoría, seguridad y troubleshooting de sistemas en producción.

### 💻 Ejemplos de Comandos

bash

```bash
# Actualizar lista de repositorios (sin instalar actualizaciones)
apt update

# Actualizar paquetes ya instalados
apt upgrade

# Buscar paquete con palabras clave
apt search "apache http server"

# Instalar paquete
apt install apache2

# Ver información detallada de un paquete
apt show apache2

# Identificar a qué paquete pertenece un archivo
dpkg -S /bin/ls

# Listar archivos de un paquete
dpkg -L coreutils | grep /bin

# Desinstalar paquete y sus dependencias no usadas
apt remove ziptool
apt autoremove

# Agregar repositorio personalizado
echo "deb http://us.archive.ubuntu.com/ubuntu/ focal main" | sudo tee /etc/apt/sources.list.d/focal.list
apt update

# Compilar e instalar desde fuente
cd tmux
./configure
make
sudo make install
```
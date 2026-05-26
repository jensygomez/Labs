---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Tema: "Lab: Manage Software, Repositories & Install Software from Source"
Fecha de Inicio: 2026-04-29
Dificultad: Intermedio-Medio
Tareas Totales: "7"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha      | Tiempo | Éxito | Notas Rápidas |
| :--------- | :----- | :---- | :------------ |
| `29/05/26` | 20 min | 0 %   |               |
| `16/05/26` | 20 min | 14 %  |               |
| `25/05/26` |        |       |               |
|            |        |       |               |
[[Laboratorios del LFCS]]


===================











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
#!/bin/bash

echo "[+] Creando estructura del laboratorio RHCSA..."

# Carpeta principal
mkdir -p lab-rh/{scripts,docs,ejercicios,notas}
mkdir -p lab-rh/ejercicios/{dia1,dia2,dia3,dia4,dia5,dia6,dia7,dia8,dia9}

#########################
# Crear Dockerfile
#########################

cat << 'EOF' > lab-rh/Dockerfile
FROM rockylinux:9

# Crear usuario del examen
RUN useradd -m phoenix && \
    echo "phoenix:lab123" | chpasswd

# Instalar utilidades necesarias
RUN dnf install -y procps-ng iproute hostname iputils net-tools vim nano \
    passwd man-db sudo && \
    dnf clean all

# Permitir sudo al usuario phoenix
RUN echo "phoenix ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER phoenix
WORKDIR /home/phoenix
EOF

#########################
# Crear README.md
#########################

cat << 'EOF' > lab-rh/README.md
# Laboratorio RHCSA en Docker

Este proyecto contiene un laboratorio completo para practicar RHCSA usando contenedores Rocky Linux 9.

## 🚀 Cómo construir la imagen

docker build -t phoenix-lab .

## 🚀 Ejecutar un contenedor

docker run -it --name node1 phoenix-lab bash

## 🚀 Crear varios nodos

docker run -it --name node1 phoenix-lab bash
docker run -it --name node2 phoenix-lab bash
docker run -it --name node3 phoenix-lab bash
docker run -it --name node4 phoenix-lab bash

## 🚀 Ingresar a un nodo ya existente
docker start -ai node1

## 🧹 Contenedor que se borra al salir
docker run --rm -it phoenix-lab bash

## Carpetas
- /docs → Teoría día por día
- /ejercicios → Tareas por día
- /scripts → Scripts automáticos
- /notas → Apuntes personales
EOF

#########################
# Scripts
#########################

cat << 'EOF' > lab-rh/scripts/setup.sh
#!/bin/bash
echo "[+] Inicializando entorno del laboratorio..."

mkdir -p /home/phoenix/reportes
mkdir -p /home/phoenix/pruebas

echo "[+] Carpetas creadas."
EOF

cat << 'EOF' > lab-rh/scripts/test-user.sh
#!/bin/bash
echo "Usuario actual:"
whoami
echo "Información del usuario:"
id
EOF

cat << 'EOF' > lab-rh/scripts/check-system.sh
#!/bin/bash
echo "=== Estado del Sistema ==="
hostname
uname -r
df -h
free -m
ps aux | head
EOF

chmod +x lab-rh/scripts/*.sh

#########################
# Docs
#########################

declare -A docs=(
  ["dia1-comandos-basicos.md"]="# Día 1 — Comandos básicos

- pwd
- ls -l
- whoami
- id
- ps aux
- df -h"
  ["dia2-permisos-y-procesos.md"]="# Día 2 — Permisos y procesos

- chmod
- chown
- ps
- kill"
  ["dia3-storage-lvm.md"]="# Día 3 — Storage y LVM

- lsblk
- pvcreate
- vgcreate
- lvcreate"
  ["dia4-selinux.md"]="# Día 4 — SELinux

- getenforce
- setenforce
- semanage"
  ["dia5-networking.md"]="# Día 5 — Networking

- nmcli
- ip a
- ping"
  ["dia6-firewalld.md"]="# Día 6 — firewalld

- firewall-cmd"
  ["dia7-scripting.md"]="# Día 7 — Bash scripting

- variables
- loops"
  ["dia8-lab-mixto.md"]="# Día 8 — Laboratorio mixto"
  ["dia9-simulacro.md"]="# Día 9 — Simulacro RHCSA real"
)

for file in "${!docs[@]}"; do
    echo "${docs[$file]}" > "lab-rh/docs/$file"
done

#########################
# Ejercicios día 1
#########################

cat << 'EOF' > lab-rh/ejercicios/dia1/ejercicio1.md
# Ejercicio Día 1 — Básicos

1. Mostrar la ruta actual.
2. Crear la carpeta /home/phoenix/prueba1
3. Crear un archivo info.txt dentro.
4. Listar procesos con ps aux.
5. Guardar reporte en /home/phoenix/reportes/dia1.txt
EOF

#########################
# Notas
#########################

cat << 'EOF' > lab-rh/notas/comandos-importantes.md
journalctl -xe
nmcli device status
lsblk
systemctl status
firewall-cmd --list-all
EOF

cat << 'EOF' > lab-rh/notas/errores-comunes.md
- Olvidar habilitar servicios.
- No montar particiones después de crearlas.
EOF

cat << 'EOF' > lab-rh/notas/soluciones-rapidas.md
systemctl restart servicio
journalctl -u servicio
EOF

echo "[✔] Laboratorio creado en la carpeta lab-rh/"

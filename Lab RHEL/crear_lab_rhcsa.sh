#!/bin/bash

echo "======================================="
echo "  LABORATORIO RHCSA - INSTALADOR TOTAL"
echo "======================================="

#-------------------------------------------------------
# 1. Crear estructura de carpetas
#-------------------------------------------------------

echo "[+] Creando estructura del laboratorio..."

mkdir -p lab-rh/{scripts,docs,ejercicios,notas}
mkdir -p lab-rh/ejercicios/{dia1,dia2,dia3,dia4,dia5,dia6,dia7,dia8,dia9}

#-------------------------------------------------------
# 2. Dockerfile
#-------------------------------------------------------

echo "[+] Creando Dockerfile..."

cat << 'EOF' > lab-rh/Dockerfile
FROM rockylinux:9

# Crear usuario del examen
RUN useradd -m phoenix && \
    echo "phoenix:lab123" | chpasswd

# Instalar utilidades necesarias
RUN dnf install -y procps-ng iproute hostname iputils net-tools vim nano \
    passwd man-db sudo which tar zip unzip && \
    dnf clean all

# Permitir sudo al usuario phoenix
RUN echo "phoenix ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER phoenix
WORKDIR /home/phoenix
EOF

#-------------------------------------------------------
# 3. README.md
#-------------------------------------------------------

echo "[+] Creando README.md..."

cat << 'EOF' > lab-rh/README.md
# Laboratorio RHCSA en Docker

## 🚀 Crear imagen
docker build -t phoenix-lab .

## 🚀 Crear contenedores
docker run -d --name node1 phoenix-lab tail -f /dev/null
docker run -d --name node2 phoenix-lab tail -f /dev/null
docker run -d --name node3 phoenix-lab tail -f /dev/null
docker run -d --name node4 phoenix-lab tail -f /dev/null

## 🚀 Acceder a un nodo
docker exec -it node1 bash
docker exec -it node2 bash

## ❌ Borrar contenedores
docker rm -f node1 node2 node3 node4
EOF

#-------------------------------------------------------
# 4. Scripts internos
#-------------------------------------------------------

echo "[+] Creando scripts..."

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

#-------------------------------------------------------
# 5. Documentación día por día
#-------------------------------------------------------

echo "[+] Creando documentación..."

declare -A docs=(
  ["dia1-comandos-basicos.md"]="# Día 1 — Comandos básicos\n\npwd\nls -l\nwhoami\nid\nps aux\ndf -h"
  ["dia2-permisos-y-procesos.md"]="# Día 2 — Permisos y procesos\n\nchmod\nchown\nps\nkill"
  ["dia3-storage-lvm.md"]="# Día 3 — Storage y LVM\n\nlsblk\npvcreate\nvgcreate\nlvcreate"
  ["dia4-selinux.md"]="# Día 4 — SELinux\n\ngetenforce\nsetenforce\nsemanage"
  ["dia5-networking.md"]="# Día 5 — Networking\n\nnmcli\nip a\nping"
  ["dia6-firewalld.md"]="# Día 6 — firewalld\n\nfirewall-cmd"
  ["dia7-scripting.md"]="# Día 7 — Scripting"
  ["dia8-lab-mixto.md"]="# Día 8 — Lab mixto"
  ["dia9-simulacro.md"]="# Día 9 — Simulacro RHCSA"
)

for file in "${!docs[@]}"; do
    echo -e "${docs[$file]}" > "lab-rh/docs/$file"
done

#-------------------------------------------------------
# 6. Ejercicios básicos
#-------------------------------------------------------

echo "[+] Creando ejercicios..."

cat << 'EOF' > lab-rh/ejercicios/dia1/ejercicio1.md
# Ejercicio Día 1 — Básicos

1. Mostrar ruta actual.
2. Crear carpeta /home/phoenix/prueba1
3. Crear archivo info.txt
4. Listar procesos (ps aux)
5. Guardar reporte en /home/phoenix/reportes/dia1.txt
EOF

#-------------------------------------------------------
# 7. Notas personales
#-------------------------------------------------------

echo "[+] Creando notas..."

cat << 'EOF' > lab-rh/notas/comandos-importantes.md
journalctl -xe
nmcli device status
lsblk
systemctl status
firewall-cmd --list-all
EOF

cat << 'EOF' > lab-rh/notas/errores-comunes.md
- Olvidar habilitar servicios
- No montar sistemas de archivos
EOF

cat << 'EOF' > lab-rh/notas/soluciones-rapidas.md
systemctl restart servicio
journalctl -u servicio
EOF

#-------------------------------------------------------
# 8. Construir imagen Docker automáticamente
#-------------------------------------------------------

echo "[+] Construyendo la imagen Docker phoenix-lab..."
cd lab-rh
docker build -t phoenix-lab .

#-------------------------------------------------------
# 9. Crear 4 contenedores automáticamente
#-------------------------------------------------------

echo "[+] Creando contenedores node1, node2, node3, node4..."

docker run -d --name node1 phoenix-lab tail -f /dev/null
docker run -d --name node2 phoenix-lab tail -f /dev/null
docker run -d --name node3 phoenix-lab tail -f /dev/null
docker run -d --name node4 phoenix-lab tail -f /dev/null

echo "======================================="
echo "  LABORATORIO INSTALADO CORRECTAMENTE"
echo "======================================="
echo ""
echo "✔ Para entrar a un nodo:"
echo "    docker exec -it node1 bash"
echo "    docker exec -it node2 bash"
echo ""
echo "✔ Para ver los contenedores:"
echo "    docker ps"
echo ""
echo "✔ Para borrar todo:"
echo "    docker rm -f node1 node2 node3 node4"
echo ""
echo "Listo, Jensy. ¡A estudiar como en el examen!"


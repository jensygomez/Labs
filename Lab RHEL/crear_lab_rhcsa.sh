#!/bin/bash

# ================================
#  LABORATORIO RHCSA - AUTOSETUP
#  Versión optimizada para PODMAN
# ================================

set -e  # Detener el script si ocurre un error

GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
RESET="\e[0m"

echo -e "${BLUE}======================================="
echo -e "  LABORATORIO RHCSA - INSTALADOR TOTAL"
echo -e "=======================================${RESET}"

# -------------------------------
# 1. DETECTAR O INSTALAR PODMAN
# -------------------------------
echo -e "${YELLOW}[+] Verificando si podman está instalado...${RESET}"

if ! command -v podman &> /dev/null; then
    echo -e "${YELLOW}[+] Podman no encontrado. Instalando...${RESET}"
    sudo apt update
    sudo apt install -y podman podman-docker
else
    echo -e "${GREEN}[✔] Podman ya está instalado.${RESET}"
fi

# PODMAN listo
echo -e "${GREEN}[✔] Motor de contenedores listo.${RESET}"

# -------------------------------
# 2. CREAR ESTRUCTURA DE CARPETAS
# -------------------------------
echo -e "${YELLOW}[+] Creando estructura del laboratorio...${RESET}"

LAB_DIR="RHEL-LAB"
mkdir -p $LAB_DIR/{dia1,dia2,docs,notas,scripts,imagenes}

# -------------------------------
# 3. CREAR DOCKERFILE (PODMANFILE)
# -------------------------------
echo -e "${YELLOW}[+] Creando Podmanfile...${RESET}"

cat << 'EOF' > $LAB_DIR/Podmanfile
FROM rockylinux:9

# Usuario del examen
RUN useradd -m phoenix && \
    echo "phoenix:lab123" | chpasswd

# Utilidades típicas RHCSA
RUN dnf install -y procps-ng iproute hostname iputils vim nano && \
    dnf clean all

USER phoenix
WORKDIR /home/phoenix
EOF

# -------------------------------
# 4. CREAR README
# -------------------------------
echo -e "${YELLOW}[+] Creando README.md...${RESET}"

cat << 'EOF' > $LAB_DIR/README.md
# RHCSA Mini-Lab con Podman
Incluye 4 nodos tipo Rocky Linux 9 para practicar tareas del examen RHCSA.
EOF

# -------------------------------
# 5. CONSTRUIR IMAGEN
# -------------------------------
echo -e "${YELLOW}[+] Construyendo imagen podman phoenix-lab...${RESET}"

cd $LAB_DIR
podman build -t phoenix-lab -f Podmanfile .

# -------------------------------
# 6. CREAR RED (solo una vez)
# -------------------------------
echo -e "${YELLOW}[+] Verificando red del laboratorio...${RESET}"

if ! podman network exists rhel_lab_net; then
    podman network create rhel_lab_net
    echo -e "${GREEN}[✔] Red creada: rhel_lab_net${RESET}"
else
    echo -e "${GREEN}[✔] La red rhel_lab_net ya existe${RESET}"
fi

# -------------------------------
# 7. CREAR 4 CONTENEDORES
# -------------------------------
echo -e "${YELLOW}[+] Creando contenedores node1..node4${RESET}"

for i in 1 2 3 4; do
    if podman ps -a --format "{{.Names}}" | grep -q "node${i}"; then
        echo -e "${GREEN}[✔] node${i} ya existe (no se recrea)${RESET}"
    else
        podman run -d --name node${i} --network rhel_lab_net phoenix-lab sleep infinity
        echo -e "${GREEN}[✔] node${i} creado${RESET}"
    fi
done

# -------------------------------
# 8. FINAL
# -------------------------------
echo -e "${BLUE}======================================="
echo -e "  LABORATORIO RHCSA INSTALADO"
echo -e "=======================================${RESET}"

echo -e "${GREEN}✔ Para entrar a un nodo:${RESET}"
echo -e "    podman exec -it node1 bash"
echo -e "    podman exec -it node2 bash"
echo -e "    podman exec -it node3 bash"
echo -e "    podman exec -it node4 bash"

echo -e "${GREEN}✔ Ver contenedores:${RESET}"
echo -e "    podman ps"

echo -e "${GREEN}✔ Borrar todo:${RESET}"
echo -e "    podman rm -f node1 node2 node3 node4"
echo -e "    podman network rm rhel_lab_net"

echo -e "${GREEN}Listo, Jensy. ¡Tu laboratorio RHCSA está funcionando!${RESET}"


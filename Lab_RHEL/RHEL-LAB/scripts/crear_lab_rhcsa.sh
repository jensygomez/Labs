#!/bin/bash

# ================================
#  LABORATORIO RHCSA - AUTOSETUP
#  100% DOCKER
# ================================

set -e

GREEN="\e[32m"
BLUE="\e[34m"
YELLOW="\e[33m"
RESET="\e[0m"

echo -e "${BLUE}======================================="
echo -e "  LABORATORIO RHCSA - INSTALADOR TOTAL"
echo -e "=======================================${RESET}"

# -------------------------------
# 1. DETECTAR DOCKER
# -------------------------------
echo -e "${YELLOW}[+] Verificando si Docker está instalado...${RESET}"

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}[+] Docker no está instalado. Abortando.${RESET}"
    echo -e "Instálalo con:"
    echo -e "  sudo apt install docker-ce docker-ce-cli containerd.io"
    exit 1
else
    echo -e "${GREEN}[✔] Docker ya está instalado.${RESET}"
fi

echo -e "${GREEN}[✔] Motor Docker listo.${RESET}"

# -------------------------------
# 2. CREAR DIRECTORIOS
# -------------------------------
echo -e "${YELLOW}[+] Creando estructura del laboratorio...${RESET}"

LAB_DIR="RHEL-LAB"
mkdir -p $LAB_DIR/{dia1,dia2,docs,notas,scripts,imagenes}

# -------------------------------
# 3. CREAR DOCKERFILE
# -------------------------------
echo -e "${YELLOW}[+] Creando Dockerfile...${RESET}"

cat << 'EOF' > $LAB_DIR/Dockerfile
FROM rockylinux:9

# Contraseña para root (cámbiala por la que quieras)
RUN echo "root:lab123" | chpasswd

RUN useradd -m phoenix && \
    echo "phoenix:lab123" | chpasswd

RUN dnf install -y procps-ng iproute hostname iputils vim nano && \
    dnf clean all

USER phoenix
WORKDIR /home/phoenix
EOF

# -------------------------------
# 4. README
# -------------------------------
echo -e "${YELLOW}[+] Creando README.md...${RESET}"

cat << 'EOF' > $LAB_DIR/README.md
# RHCSA Mini-Lab con DOCKER
Incluye 4 contenedores Rocky Linux 9
EOF

# -------------------------------
# 5. BUILD IMAGEN
# -------------------------------
echo -e "${YELLOW}[+] Construyendo imagen Docker phoenix-lab...${RESET}"

cd $LAB_DIR
docker build -t phoenix-lab .

# -------------------------------
# 6. RED
# -------------------------------
echo -e "${YELLOW}[+] Verificando red del laboratorio...${RESET}"

if ! docker network ls --format "{{.Name}}" | grep -q "rhel_lab_net"; then
    docker network create rhel_lab_net
    echo -e "${GREEN}[✔] Red creada: rhel_lab_net${RESET}"
else
    echo -e "${GREEN}[✔] La red rhel_lab_net ya existe${RESET}"
fi

# -------------------------------
# 7. CONTENEDORES
# -------------------------------
echo -e "${YELLOW}[+] Creando contenedores node1..node4${RESET}"

for i in 1 2 3 4; do
    if docker ps -a --format "{{.Names}}" | grep -q "node${i}"; then
        echo -e "${GREEN}[✔] node${i} ya existe (aplicando autostart)...${RESET}"
        docker update --restart unless-stopped node${i}
    else
        docker run -d \
            --restart unless-stopped \
            --name node${i} \
            --network rhel_lab_net \
            phoenix-lab sleep infinity
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
echo "  docker exec -it node1 bash"
echo "  docker exec -it node2 bash"

echo -e "${GREEN}✔ Ver contenedores:${RESET}"
echo "  docker ps"

echo -e "${GREEN}✔ Borrar todo:${RESET}"
echo "  docker rm -f node1 node2 node3 node4"
echo "  docker network rm rhel_lab_net"

echo -e "${GREEN}Listo Jensy, tu laboratorio RHCSA está funcionando con Docker REAL.${RESET}"

echo -e "=======================================${RESET}"


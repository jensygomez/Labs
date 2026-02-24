#!/usr/bin/env bash
# ============================================================================
# BOOTSTRAP - Prepara una VM limpia con todas las imágenes Docker necesarias
# para los laboratorios LFCS/LFCE
# ============================================================================

set -Eeuo pipefail

VERDE='\033[0;32m'
ROJO='\033[0;31m'
NC='\033[0m'

ok()  { echo -e "${VERDE}✔ $*${NC}"; }
err() { echo -e "${ROJO}❌ $*${NC}" >&2; exit 1; }

# Verificar Docker
command -v docker >/dev/null 2>&1 || err "Docker no está instalado"

# Crear directorio de trabajo
mkdir -p ~/Labs
cd ~/Labs

ok "=== PASO 1: Descargar imagen base Ubuntu 24.04 ==="
docker pull ubuntu:24.04

ok "=== PASO 2: Crear Dockerfile para ubuntu-net ==="
cat > Dockerfile << 'EOF'
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y \
      iproute2 \
      iputils-ping \
      iptables \
      net-tools \
      tcpdump \
      curl && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
CMD ["bash"]
EOF

ok "=== PASO 3: Construir ubuntu-net:24.04 ==="
docker build -t ubuntu-net:24.04 .

ok "=== PASO 4: Crear Dockerfile para ubuntu-ldap ==="
cat > Dockerfile.ldap << 'EOF'
FROM ubuntu-net:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    echo "slapd slapd/root_password password admin123" | debconf-set-selections && \
    echo "slapd slapd/root_password_again password admin123" | debconf-set-selections && \
    echo "slapd slapd/domain string laboratorio.local" | debconf-set-selections && \
    echo "slapd shared/organization string Laboratorio" | debconf-set-selections && \
    apt install -y slapd ldap-utils iproute2 net-tools procps
EXPOSE 389 636
CMD ["sleep", "infinity"]
EOF

ok "=== PASO 5: Construir ubuntu-ldap:24.04 ==="
docker build -t ubuntu-ldap:24.04 -f Dockerfile.ldap .

ok "=== PASO 6: Crear Dockerfile para ubuntu-pc ==="
cat > Dockerfile.pc << 'EOF'
FROM ubuntu-net:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y \
      sssd \
      sssd-ldap \
      libpam-sss \
      libnss-sss \
      ldap-utils \
      openssh-client \
      nfs-common \
      passwd && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*
CMD ["bash"]
EOF

ok "=== PASO 7: Construir ubuntu-pc:24.04 ==="
docker build -t ubuntu-pc:24.04 -f Dockerfile.pc .

ok "=== PASO 8: Clonar los scripts de laboratorio ==="
git clone https://github.com/tu-repo/Labs.git ~/Labs/Golden-Base 2>/dev/null || \
  echo "Ya existe el repositorio"

ok "=== PASO 9: Verificar imágenes ==="
docker images | head -10

ok "✅¡TODO LISTO! VM preparada para los laboratorios"
echo ""
echo "Para ejecutar los laboratorios:"
echo "  cd ~/Labs/Golden-Base"
echo "  ./engine.sh"
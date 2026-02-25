#!/usr/bin/env bash
# ~/Labs/Golden-Base/bootstrap.sh
# ============================================================================
# BOOTSTRAP - Prepara una VM limpia con todas las imágenes Docker necesarias
# para los laboratorios LFCS/LFCE
# ============================================================================


set -Eeuo pipefail

VERDE='\033[0;32m'
AMARILLO='\033[0;33m'
ROJO='\033[0;31m'
NC='\033[0m'

ok()    { echo -e "${VERDE}✔ $*${NC}"; }
warn()  { echo -e "${AMARILLO}⚠ $*${NC}"; }
err()   { echo -e "${ROJO}❌ $*${NC}" >&2; exit 1; }

# Verificar si se ejecuta como root (no recomendado, mejor con sudo)
if [[ $EUID -eq 0 ]]; then
    err "No ejecutes este script como root. Ejecútalo con un usuario normal y usa sudo cuando sea necesario"
fi

# ============================================================================
# PASO 0: Instalar y configurar Docker correctamente
# ============================================================================
ok "=== PASO 0: Instalando Docker desde el repositorio oficial ==="

# Actualizar sistema
warn "Actualizando lista de paquetes..."
sudo apt update

# Instalar dependencias
warn "Instalando dependencias necesarias..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release

# Añadir clave GPG oficial de Docker
warn "Añadiendo clave GPG de Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Añadir repositorio estable
warn "Configurando repositorio de Docker..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker Engine
warn "Instalando Docker Engine..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verificar que Docker está instalado
if ! command -v docker >/dev/null 2>&1; then
    err "Fallo la instalación de Docker"
fi

# Iniciar y habilitar servicio
warn "Configurando servicio Docker..."
sudo systemctl enable docker
sudo systemctl start docker

# Verificar que el servicio está corriendo
if ! sudo systemctl is-active --quiet docker; then
    err "El servicio Docker no está corriendo"
fi

# Añadir usuario al grupo docker
warn "Añadiendo usuario $USER al grupo docker..."
sudo usermod -aG docker $USER

ok "Docker instalado correctamente: $(docker --version)"

# Advertencia sobre el grupo docker
warn "IMPORTANTE: Para usar Docker sin sudo, CIERRA SESIÓN y VUELVE A ENTRAR"
warn "O ejecuta: newgrp docker (solo para la sesión actual)"

# ============================================================================
# Continuar con el resto del script original
# ============================================================================

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

# Instalar slapd sin debconf
RUN apt update && \
    apt install -y slapd ldap-utils iproute2 net-tools procps && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Configurar contraseña admin123
RUN mkdir -p /etc/ldap/slapd.d /var/lib/ldap && \
    chown -R openldap:openldap /etc/ldap/slapd.d /var/lib/ldap

COPY ldap-config.ldif /tmp/
RUN slapd -u openldap -g openldap -h "ldapi:///" -F /etc/ldap/slapd.d/ && \
    sleep 3 && \
    ldapmodify -Y EXTERNAL -H ldapi:/// -f /tmp/ldap-config.ldif && \
    pkill slapd || true && \
    sleep 2

EXPOSE 389 636
CMD ["slapd", "-h", "ldap:/// ldapi:///", "-u", "openldap", "-g", "openldap", "-d", "0"]
EOF

# Crear archivo de configuración LDAP
cat > ldap-config.ldif << 'EOF'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: {SSHA}tucontraseñahash
EOF

# Generar hash de contraseña
PASS_HASH=$(slappasswd -s admin123)
sed -i "s|{SSHA}tucontraseñahash|$PASS_HASH|" ldap-config.ldif

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
if [ ! -d ~/Labs/Golden-Base ]; then
    git clone https://github.com/tu-repo/Labs.git ~/Labs/Golden-Base || \
        warn "No se pudo clonar el repositorio, continúa sin los scripts"
else
    ok "Repositorio ya existe"
fi

ok "=== PASO 9: Verificar imágenes ==="
docker images | head -10

ok "✅ ¡TODO LISTO! VM preparada para los laboratorios"
echo ""
echo "📋 IMPORTANTE:"
echo "  1. Si es primera vez que instalas Docker, CIERRA SESIÓN y VUELVE A ENTRAR"
echo "  2. Luego ejecuta: cd ~/Labs/Golden-Base"
echo "  3. Y finalmente: ./engine.sh"
echo ""
echo "💡 Para verificar Docker sin cerrar sesión ahora: newgrp docker"
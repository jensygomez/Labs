#!/bin/bash
# =============================================================
# BASE SETUP - Rocky Linux 9.7 - Golden Image para 400 Labs
# Cubre: Fundamentos, Usuarios, Storage, Systemd, Network,
#        Servicios de red, Seguridad, Podman, Bash, Boot
# Ejecutar como root: bash setup_base.sh
# =============================================================

# set -euo pipefail
LOG="/var/log/lab_setup.log"
exec > >(tee -a "$LOG") 2>&1

echo "======================================"
echo " Rocky 9.7 - Lab Base Setup"
echo " $(date)"
echo "======================================"

# --------------------------------------------------------------
# 0. ACTUALIZAR SISTEMA
# --------------------------------------------------------------
echo "[0] Actualizando sistema base..."
dnf update -y
dnf install -y epel-release

# --------------------------------------------------------------
# 1. FUNDAMENTOS DEL SISTEMA
# --------------------------------------------------------------
echo "[1] Herramientas de fundamentos..."
dnf install -y \
    bash-completion \
    vim \
    nano \
    man-db \
    man-pages \
    info \
    tree \
    wget \
    curl \
    git \
    tar \
    gzip \
    bzip2 \
    xz \
    unzip \
    zip \
    file \
    which \
    lsof \
    strace \
    ltrace \
    mlocate \
    mlocate \
    findutils \
    diffutils \
    patch \
    bc \
    tmux \
    screen \
    less \
    util-linux \
    coreutils \
    procps-ng \
    psmisc \
    bind-utils \
    net-tools \
    iproute \
    iputils

# --------------------------------------------------------------
# 2. USUARIOS Y GRUPOS
# --------------------------------------------------------------
echo "[2] Herramientas para usuarios y grupos..."
dnf install -y \
    shadow-utils \
    sudo \
    pam \
    sssd \
    authselect \
    oddjob \
    oddjob-mkhomedir \
    acl \
    attr

# --------------------------------------------------------------
# 3. ALMACENAMIENTO
# --------------------------------------------------------------
echo "[3] Herramientas de almacenamiento..."
dnf install -y \
    lvm2 \
    parted \
    gdisk \
    fdisk \
    e2fsprogs \
    xfsprogs \
    dosfstools \
    btrfs-progs \
    mdadm \
    cryptsetup \
    device-mapper \
    device-mapper-multipath \
    stratisd \
    stratis-cli \
    nfs-utils \
    autofs \
    quota \
    samba \
    samba-client \
    cifs-utils \
    iscsi-initiator-utils \
    sg3_utils \
    smartmontools \
    hdparm \
    dd \
    rsync

# --------------------------------------------------------------
# 4. SYSTEMD Y PROCESOS
# --------------------------------------------------------------
echo "[4] Herramientas systemd y procesos..."
dnf install -y \
    systemd \
    systemd-udev \
    systemd-resolved \
    systemd-journal-remote \
    at \
    cronie \
    tuned \
    irqbalance \
    htop \
    atop \
    iotop \
    sysstat \
    dstat \
    perf \
    numactl \
    schedtool \
    audit \
    rsyslog

# --------------------------------------------------------------
# 5. NETWORKING
# --------------------------------------------------------------
echo "[5] Herramientas de networking..."
dnf install -y \
    NetworkManager \
    NetworkManager-tui \
    NetworkManager-team \
    NetworkManager-bond \
    teamd \
    bridge-utils \
    vlan \
    iptables \
    iptables-nft \
    nftables \
    firewalld \
    tcpdump \
    wireshark-cli \
    nmap \
    nmap-ncat \
    traceroute \
    mtr \
    iperf3 \
    ethtool \
    iproute-tc \
    ipset \
    whois \
    telnet \
    socat \
    conntrack-tools

# --------------------------------------------------------------
# 6. SERVICIOS DE RED
# --------------------------------------------------------------
echo "[6] Servicios de red..."
dnf install -y \
    httpd \
    httpd-tools \
    mod_ssl \
    nginx \
    vsftpd \
    openssh-server \
    openssh-clients \
    postfix \
    dovecot \
    bind \
    bind-utils \
    dnsmasq \
    dhcp-server \
    dhcp-client \
    chrony \
    ntp \
    squid \
    haproxy \
    mariadb-server \
    mariadb \
    postgresql-server \
    postgresql

# --------------------------------------------------------------
# 7. SEGURIDAD
# --------------------------------------------------------------
echo "[7] Herramientas de seguridad..."
dnf install -y \
    openssl \
    openssl-libs \
    gnupg2 \
    firewalld \
    fail2ban \
    aide \
    scap-security-guide \
    openscap-scanner \
    audit \
    auditd \
    policycoreutils \
    policycoreutils-python-utils \
    setools-console \
    setroubleshoot-server \
    libsemanage \
    chkrootkit \
    rkhunter \
    lynis \
    nss-tools \
    certbot \
    acl

# --------------------------------------------------------------
# 8. CONTENEDORES CON PODMAN
# --------------------------------------------------------------
echo "[8] Podman y contenedores..."
dnf install -y \
    podman \
    podman-compose \
    podman-docker \
    buildah \
    skopeo \
    containers-common \
    crun \
    fuse-overlayfs \
    slirp4netns \
    container-selinux

# Habilitar rootless podman
echo "user.max_user_namespaces=28633" >> /etc/sysctl.d/99-podman.conf
sysctl --system

# --------------------------------------------------------------
# 9. SCRIPTING BASH
# --------------------------------------------------------------
echo "[9] Herramientas para scripting..."
dnf install -y \
    bash \
    bash-completion \
    gawk \
    sed \
    grep \
    perl \
    python3 \
    python3-pip \
    jq \
    xmlstarlet \
    expect \
    dialog \
    ShellCheck \
    bats \
    make \
    gcc \
    git

# --------------------------------------------------------------
# 10. BOOT AND RECOVERY
# --------------------------------------------------------------
echo "[10] Herramientas de boot y recovery..."
dnf install -y \
    grub2 \
    grub2-tools \
    grub2-efi-x64 \
    shim \
    dracut \
    dracut-tools \
    dracut-network \
    dracut-squash \
    kernel-tools \
    syslinux \
    efibootmgr \
    gdb \
    crash \
    kexec-tools \
    systemd-boot-unsigned \
    testdisk \
    ddrescue \
    memtest86+ \
    xfsdump

# --------------------------------------------------------------
# EXTRAS: Utilidades generales de lab
# --------------------------------------------------------------
echo "[EXTRA] Utilidades generales de laboratorio..."
dnf install -y \
    bash-completion \
    command-not-found \
    words \
    cowsay \
    figlet \
    fortune-mod \
    sl

# Activar bash-completion para todos los usuarios
echo "source /etc/profile.d/bash_completion.sh" >> /etc/bashrc

# --------------------------------------------------------------
# HABILITAR SERVICIOS BASE
# --------------------------------------------------------------
echo "[SERVICIOS] Habilitando servicios esenciales..."
systemctl enable --now chronyd
systemctl enable --now auditd
systemctl enable --now rsyslog
systemctl enable --now tuned
systemctl enable cronie
systemctl enable firewalld
# NOTA: httpd, nginx, mariadb etc. los arrancas en cada lab

# --------------------------------------------------------------
# CONFIGURACIÓN DE JOURNAL (persistente)
# --------------------------------------------------------------
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal
sed -i 's/#Storage=auto/Storage=persistent/' /etc/systemd/journald.conf
systemctl restart systemd-journald

# --------------------------------------------------------------
# ACTUALIZAR BASE DE DATOS DE COMANDOS
# --------------------------------------------------------------
mandb
updatedb 2>/dev/null || true

# --------------------------------------------------------------
# SNAPSHOT INFO
# --------------------------------------------------------------
echo ""
echo "======================================"
echo " SETUP COMPLETADO - $(date)"
echo " Esta VM está lista para clonar."
echo " Temas cubiertos: 10/10"
echo " Log: $LOG"
echo "======================================"

echo ""
echo "PRÓXIMOS PASOS ANTES DE CLONAR:"
echo "  1. Revisa el log: cat $LOG"
echo "  2. Limpia el historial: history -c && > ~/.bash_history"
echo "  3. Limpia IDs de red: rm -f /etc/machine-id && systemd-machine-id-setup"
echo "  4. Apaga la VM y toma el snapshot base en VirtualBox/VMware"
echo "  5. Crea clones enlazados desde ese snapshot"
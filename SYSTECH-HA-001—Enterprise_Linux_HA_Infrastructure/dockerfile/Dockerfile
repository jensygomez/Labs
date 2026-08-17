# dockerfile/Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Instalar dependencias base
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    unzip \
    gnupg \
    software-properties-common \
    python3 \
    python3-pip \
    python3-venv \
    openssh-client \
    iputils-ping \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# 2. Instalar OpenTofu
RUN curl -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
RUN chmod +x install-opentofu.sh
RUN ./install-opentofu.sh --install-method deb
RUN rm install-opentofu.sh

# 3. Instalar Ansible
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir ansible ansible-lint

# 4. Crear directorio de trabajo
WORKDIR /workspace

# Crear symlink para que SSH encuentre la llave desde cualquier directorio
RUN mkdir -p /workspace/terraform/.ssh && \
    ln -sf /workspace/.ssh/id_lxd_fleet /workspace/terraform/.ssh/id_lxd_fleet 2>/dev/null || true


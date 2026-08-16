FROM alpine:3.19

# Instalar dependencias del sistema de forma limpia
RUN apk add --no-cache \
    python3 \
    py3-pip \
    openssh-client \
    git \
    bash \
    curl \
    jq \
    opentofu

# Configurar entorno virtual e instalar Ansible + Proxmox SDK
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install ansible proxmoxer requests

ENV PATH="/opt/venv/bin:$PATH"

# Instalar colección de Ansible para Proxmox
RUN ansible-galaxy collection install community.general

WORKDIR /workspace

CMD ["/bin/bash"]

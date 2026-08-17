# dockerfile/Dockerfile
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ==========================================
# 1. Dependencias base + herramientas de uso diario
# ==========================================
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
    dnsutils \
    bash-completion \
    vim \
    nano \
    tree \
    htop \
    ripgrep \
    fzf \
    tmux \
    less \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# 2. OpenTofu
# ==========================================
RUN curl -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh \
    && chmod +x install-opentofu.sh \
    && ./install-opentofu.sh --install-method deb \
    && rm install-opentofu.sh

# ==========================================
# 3. Ansible (+ argcomplete para autocompletado real de subcomandos)
# ==========================================
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir ansible ansible-lint argcomplete

# ==========================================
# 4. Crear el usuario jensyg con HOME=/workspace (FIX DE RAÍZ)
#    Esto es lo que faltaba: sin esto, ~ no se resuelve dentro
#    del contenedor porque no hay entrada en /etc/passwd para
#    el UID que --userns=keep-id mapea desde el host.
# ==========================================
RUN useradd -m -d /workspace -s /bin/bash -u 1000 jensyg && \
    mkdir -p /workspace/terraform && \
    chown -R jensyg:jensyg /workspace

# ==========================================
# 5. Autocompletado: git, tofu/terraform, ansible
# ==========================================
RUN echo 'source /etc/bash_completion' >> /etc/bash.bashrc && \
    echo 'source /usr/share/bash-completion/completions/git' >> /etc/bash.bashrc 2>/dev/null || true

# Autocompletado de OpenTofu (usa el mismo formato que terraform -install-autocomplete)
RUN echo 'complete -C /usr/bin/tofu tofu' >> /etc/bash.bashrc

# Autocompletado de Ansible vía argcomplete (ansible, ansible-playbook, ansible-vault, etc.)
RUN echo 'eval "$(register-python-argcomplete ansible-playbook 2>/dev/null)"' >> /etc/bash.bashrc && \
    echo 'eval "$(register-python-argcomplete ansible-vault 2>/dev/null)"' >> /etc/bash.bashrc && \
    echo 'eval "$(register-python-argcomplete ansible-galaxy 2>/dev/null)"' >> /etc/bash.bashrc

# Prompt un poco más útil (muestra directorio actual siempre)
RUN echo 'PS1="\[\033[1;36m\][systech-control]\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] \$ "' >> /etc/bash.bashrc

# ==========================================
# 6. Directorio de trabajo final
# ==========================================
WORKDIR /workspace/terraform
USER jensyg

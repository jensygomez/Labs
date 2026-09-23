FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ==========================================
# 1. Dependencias base + incus-client + TAILSCALE
# ==========================================
RUN apt-get update && apt-get install -y curl gnupg

# Agregar repositorio de Incus
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://pkgs.zabbly.com/key.asc -o /etc/apt/keyrings/zabbly.asc && \
    printf "Enabled: yes\nTypes: deb\nURIs: https://pkgs.zabbly.com/incus/stable\nSuites: jammy\nComponents: main\nArchitectures: %s\nSigned-By: /etc/apt/keyrings/zabbly.asc\n" "$(dpkg --print-architecture)" > /etc/apt/sources.list.d/zabbly-incus-stable.sources

# Agregar repositorio de Tailscale
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list

# Instalar todo junto
RUN apt-get update && apt-get install -y \
    curl git jq unzip gnupg software-properties-common bc \
    python3 python3-pip python3-venv python3-yaml \
    openssh-client iputils-ping net-tools dnsutils \
    bash-completion vim nano tree htop ripgrep fzf tmux less byobu \
    graphviz incus-client lsof python3-passlib \
    tailscale sudo sshpass \
    && rm -rf /var/lib/apt/lists/*

# ==========================================
# 2. OpenTofu
# ==========================================
RUN curl -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh \
    && chmod +x install-opentofu.sh \
    && ./install-opentofu.sh --install-method deb \
    && rm install-opentofu.sh

# ==========================================
# 3. Ansible (+ argcomplete, PyYAML y zabbix-utils)
# ==========================================
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir ansible ansible-lint argcomplete PyYAML zabbix-utils

# ==========================================
# 4. kubectl (cliente de Kubernetes)
# ==========================================
RUN curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl

# ==========================================
# 5. Crear el usuario jensyg con HOME=/workspace
# ==========================================
RUN useradd -m -d /workspace -s /bin/bash -u 1000 jensyg && \
    mkdir -p /workspace/terraform && \
    chown -R jensyg:jensyg /workspace

# ==========================================
# 5.1 Permisos Sudo sin contraseña para jensyg
# ==========================================
RUN echo "jensyg ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jensyg && \
    chmod 0440 /etc/sudoers.d/jensyg

# ==========================================
# 6. Autocompletado y Prompt
# ==========================================
RUN echo 'source /etc/bash_completion' >> /etc/bash.bashrc && \
    echo 'source /usr/share/bash-completion/completions/git' >> /etc/bash.bashrc 2>/dev/null || true
RUN echo 'complete -C /usr/bin/tofu tofu' >> /etc/bash.bashrc
RUN echo 'eval "$(register-python-argcomplete ansible-playbook 2>/dev/null)"' >> /etc/bash.bashrc && \
    echo 'eval "$(register-python-argcomplete ansible-vault 2>/dev/null)"' >> /etc/bash.bashrc && \
    echo 'eval "$(register-python-argcomplete ansible-galaxy 2>/dev/null)"' >> /etc/bash.bashrc
RUN echo 'PS1="\[\033[1;36m\][k8s-control]\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] \$ "' >> /etc/bash.bashrc

# ==========================================
# 6.1 Autocompletado y alias de kubectl (kb)
# ==========================================
RUN echo 'source <(kubectl completion bash)' >> /etc/bash.bashrc && \
    echo 'alias kb=kubectl' >> /etc/bash.bashrc && \
    echo 'complete -o default -F __start_kubectl kb' >> /etc/bash.bashrc

# ==========================================
# 7. EntryPoint para inyección segura de secretos
# ==========================================
COPY dockerfile/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ==========================================
# 8. Directorio de trabajo final
# ==========================================
WORKDIR /workspace/terraform
USER jensyg

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]

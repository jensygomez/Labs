FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# ==========================================
# 1. Dependencias base + herramientas de uso diario
# ==========================================
RUN apt-get update && apt-get install -y \
    curl git jq unzip gnupg software-properties-common \
    python3 python3-pip python3-venv python3-yaml \
    openssh-client iputils-ping net-tools dnsutils \
    bash-completion vim nano tree htop ripgrep fzf tmux less \
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
# 4. Crear el usuario jensyg con HOME=/workspace
# ==========================================
RUN useradd -m -d /workspace -s /bin/bash -u 1000 jensyg && \
    mkdir -p /workspace/terraform && \
    chown -R jensyg:jensyg /workspace

# ==========================================
# 5. Autocompletado y Prompt
# ==========================================
RUN echo 'source /etc/bash_completion' >> /etc/bash.bashrc && \
    echo 'source /usr/share/bash-completion/completions/git' >> /etc/bash.bashrc 2>/dev/null || true
RUN echo 'complete -C /usr/bin/tofu tofu' >> /etc/bash.bashrc
RUN echo 'eval "$(register-python-argcomplete ansible-playbook 2>/dev/null)"' >> /etc/bash.bashrc && \
    echo 'eval "$(register-python-argcomplete ansible-vault 2>/dev/null)"' >> /etc/bash.bashrc && \
    echo 'eval "$(register-python-argcomplete ansible-galaxy 2>/dev/null)"' >> /etc/bash.bashrc
RUN echo 'PS1="\[\033[1;36m\][systech-control]\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] \$ "' >> /etc/bash.bashrc

# ==========================================
# 6. EntryPoint para inyección segura de secretos
# ==========================================
COPY dockerfile/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ==========================================
# 7. Directorio de trabajo final
# ==========================================
WORKDIR /workspace/terraform
USER jensyg

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]

FROM rockylinux:9

# Crear usuario del examen
RUN useradd -m phoenix && \
    echo "phoenix:lab123" | chpasswd

# Instalar utilidades necesarias
RUN dnf install -y procps-ng iproute hostname iputils net-tools vim nano \
    passwd man-db sudo which tar zip unzip && \
    dnf clean all

# Permitir sudo al usuario phoenix
RUN echo "phoenix ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER phoenix
WORKDIR /home/phoenix

FROM rockylinux:9

# Contraseña para root (cámbiala por la que quieras)
RUN echo "root:lab123" | chpasswd

RUN useradd -m phoenix && \
    echo "phoenix:lab123" | chpasswd

RUN dnf install -y procps-ng iproute hostname iputils vim nano && \
    dnf clean all

USER phoenix
WORKDIR /home/phoenix

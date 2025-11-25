FROM rockylinux:9

# Usuario del examen
RUN useradd -m phoenix && \
    echo "phoenix:lab123" | chpasswd

# Utilidades típicas RHCSA
RUN dnf install -y procps-ng iproute hostname iputils vim nano && \
    dnf clean all

USER phoenix
WORKDIR /home/phoenix

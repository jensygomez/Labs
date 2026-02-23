# 1. Definimos la imagen base (Tu IMG_BASE)
FROM ubuntu:24.04

# 2. Evitar que las instalaciones se queden esperando interacción del usuario
ENV DEBIAN_FRONTEND=noninteractive

# 3. Ejecutar los comandos de instalación (Tu FASE 0)
# Combinamos todo en un solo RUN para que la imagen sea más ligera
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

# 4. (Opcional) Comando por defecto al arrancar
CMD ["bash"]
#!/bin/bash
# Setup con falla intencional: archivo con permiso incorrecto

apt update && apt upgrade -y

mkdir -p /tmp/lab
cd /tmp/lab

touch important_file
chmod 000 important_file  # Permisos que bloquean acceso

echo "✅ Setup completado con fallo intencional: archivo con permisos 000"

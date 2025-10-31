#!/bin/bash
# =================================================
# Setup inicial para el laboratorio
# =================================================

# Actualizar sistema
apt update && apt upgrade -y

# Crear carpeta de prueba
mkdir -p /tmp/lab
cd /tmp/lab

# Archivos de prueba
touch file1 file2
chmod 600 file1

echo "✅ Setup completado."

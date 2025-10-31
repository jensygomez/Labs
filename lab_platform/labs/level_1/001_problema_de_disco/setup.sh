#!/bin/bash
# =================================================
# Setup inicial para el laboratorio
# =================================================

apt update && apt upgrade -y

mkdir -p /tmp/lab
cd /tmp/lab

touch file1 file2
chmod 600 file1

echo "✅ Setup completado."

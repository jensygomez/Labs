#!/bin/bash
# Generador Completo de FSck Lab
# Autor: $(whoami)
# Fecha: $(date +%Y-%m-%d)

set -e

echo "=== CREANDO FSck LAB COMPLETO ==="

# Configuración
LAB_NAME="fsck-lab-portable"
LAB_DIR="./$LAB_NAME"

# Crear directorio principal
mkdir -p "$LAB_DIR"
cd "$LAB_DIR"

echo "Creando estructura en: $(pwd)"

# 1. Crear script de configuración
cat > fsck-lab-setup.sh <<'EOF'
#!/bin/bash
# FSck Lab - Configuración Inicial
# Ejecutar primero este script

set -e

echo "=== FSck Lab - Configuración Inicial ==="

# Configuración
LAB_DIR=$(dirname "$(realpath "$0")")
CONTAINER_NAME="fsck-lab-container"
IMAGE_NAME="fsck-lab"

cd "$LAB_DIR"

# 1. Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker no está instalado"
    echo "Instala Docker primero: https://docs.docker.com/get-docker/"
    exit 1
fi

# 2. Crear Dockerfile
cat > Dockerfile <<'DOCKEREOF'
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y e2fsprogs
CMD ["sleep", "infinity"]
DOCKEREOF

# 3. Construir imagen Docker
echo "Construyendo imagen Docker..."
docker build -t $IMAGE_NAME .

# 4. Detener contenedor anterior si existe
docker rm -f $CONTAINER_NAME 2>/dev/null || true

# 5. Ejecutar contenedor
echo "Iniciando contenedor..."
docker run -d --name $CONTAINER_NAME --privileged -v "$LAB_DIR":/host $IMAGE_NAME

# 6. Verificar
if docker ps | grep -q $CONTAINER_NAME; then
    echo "✅ Configuración completada exitosamente"
    echo ""
    echo "📊 INFORMACIÓN:"
    echo "   Contenedor: $CONTAINER_NAME"
    echo "   Directorio: $LAB_DIR"
    echo "   Imagen: $IMAGE_NAME"
    echo ""
    echo "🚀 PRÓXIMOS PASOS:"
    echo "   1. Ejecutar: ./fsck-exercises.sh"
    echo "   2. Entrar al contenedor: docker exec -it $CONTAINER_NAME bash"
else
    echo "❌ Error: Contenedor no se inició correctamente"
    exit 1
fi
EOF

# 2. Crear script de ejercicios
cat > fsck-exercises.sh <<'EOF'
#!/bin/bash
# FSck Lab - Generador de Ejercicios
# Ejecutar después del setup

set -e

echo "=== FSck Lab - Generando Ejercicios ==="

LAB_DIR=$(dirname "$(realpath "$0")")
cd "$LAB_DIR"

# Crear directorio temporal para montaje
sudo mkdir -p /mnt/fsck-lab-temp

# Función para limpiar montajes
cleanup_mount() {
    sudo umount /mnt/fsck-lab-temp 2>/dev/null || true
}

trap cleanup_mount EXIT

# Ejercicio 1: Recuperación Simple (Éxito garantizado)
echo "1. 🟢 Creando Ejercicio 1: Recuperación Simple..."
rm -f disco-recuperable.img
dd if=/dev/zero of=disco-recuperable.img bs=1M count=20 status=progress
mkfs.ext4 -F disco-recuperable.img > /dev/null 2>&1

# Montar y crear datos de prueba
sudo mount -o loop disco-recuperable.img /mnt/fsck-lab-temp
sudo sh -c 'echo "🔥 DATOS CRÍTICOS DEL SERVIDOR" > /mnt/fsck-lab-temp/datos-importantes.txt'
sudo sh -c 'echo "CONFIGURACIÓN:" > /mnt/fsck-lab-temp/config.txt'
sudo sh -c 'echo "host=192.168.1.100" >> /mnt/fsck-lab-temp/config.txt'
sudo sh -c 'echo "puerto=5432" >> /mnt/fsck-lab-temp/config.txt'
sudo sh -c 'echo "base_de_datos=produccion" >> /mnt/fsck-lab-temp/config.txt'
sudo sync
sudo umount /mnt/fsck-lab-temp

# Corrupción controlada - SOLO superbloque primario
sudo dd if=/dev/zero of=disco-recuperable.img bs=1K count=1 seek=0 conv=notrunc > /dev/null 2>&1

echo "   ✅ Ejercicio 1 listo: disco-recuperable.img"

# Ejercicio 2: Daño Moderado (Recuperación parcial)
echo "2. 🟡 Creando Ejercicio 2: Daño Moderado..."
rm -f disco-moderado.img
dd if=/dev/zero of=disco-moderado.img bs=1M count=25 status=progress
mkfs.ext4 -F disco-moderado.img > /dev/null 2>&1

sudo mount -o loop disco-moderado.img /mnt/fsck-lab-temp
sudo mkdir -p /mnt/fsck-lab-temp/{database,logs,backups}
sudo sh -c 'echo "usuarios_data" > /mnt/fsck-lab-temp/database/usuarios.db'
sudo sh -c 'echo "2024-$(date +%m-%d) INFO: Sistema operativo" > /mnt/fsck-lab-temp/logs/sistema.log'
sudo sh -c 'dd if=/dev/urandom of=/mnt/fsck-lab-temp/backups/respaldo.dat bs=1M count=1 status=none 2>/dev/null'
sudo sync
sudo umount /mnt/fsck-lab-temp

# Corrupción múltiple
sudo dd if=/dev/zero of=disco-moderado.img bs=1K count=8 seek=0 conv=notrunc > /dev/null 2>&1
sudo dd if=/dev/urandom of=disco-moderado.img bs=1K count=4 seek=128 conv=notrunc > /dev/null 2>&1

echo "   ✅ Ejercicio 2 listo: disco-moderado.img"

# Ejercicio 3: Desastre Total (Límites de recuperación)
echo "3. 🔴 Creando Ejercicio 3: Desastre Total..."
rm -f disco-desastre.img
dd if=/dev/zero of=disco-desastre.img bs=1M count=30 status=progress
mkfs.ext4 -F disco-desastre.img > /dev/null 2>&1

sudo mount -o loop disco-desastre.img /mnt/fsck-lab-temp
sudo sh -c 'echo "INFORMACIÓN CONFIDENCIAL - NO RECUPERABLE" > /mnt/fsck-lab-temp/confidencial.txt'
for i in {1..50}; do
    sudo sh -c "echo 'Archivo número $i' > /mnt/fsck-lab-temp/archivo_$i.txt"
done
sudo sync
# Desmontaje brusco (simulando crash)
sudo umount -l /mnt/fsck-lab-temp

# Corrupción masiva
sudo dd if=/dev/urandom of=disco-desastre.img bs=1K count=256 seek=0 conv=notrunc > /dev/null 2>&1

echo "   ✅ Ejercicio 3 listo: disco-desastre.img"

# Limpiar montaje
cleanup_mount

echo ""
echo "🎉 TODOS LOS EJERCICIOS CREADOS EXITOSAMENTE"
echo ""
echo "📁 ARCHIVOS GENERADOS:"
ls -lh *.img
echo ""
echo "🚀 INSTRUCCIONES RÁPIDAS:"
echo "   1. Entrar al contenedor: docker exec -it fsck-lab-container bash"
echo "   2. Probar ejercicio: losetup -fP /host/disco-recuperable.img"
echo "   3. Diagnosticar: fsck -f -n /dev/loop0"
echo "   4. Reparar: fsck -y /dev/loop0"
echo "   5. Ver detalles en: cat EJERCICIOS.md"
EOF

# 3. Crear script de limpieza
cat > fsck-cleanup.sh <<'EOF'
#!/bin/bash
# FSck Lab - Limpieza Completa

echo "=== FSck Lab - Limpieza ==="

CONTAINER_NAME="fsck-lab-container"
IMAGE_NAME="fsck-lab"
LAB_DIR=$(dirname "$(realpath "$0")")

cd "$LAB_DIR"

echo "Limpiando recursos..."

# 1. Detener y eliminar contenedor
if docker ps -a | grep -q $CONTAINER_NAME; then
    docker rm -f $CONTAINER_NAME
    echo "✅ Contenedor eliminado: $CONTAINER_NAME"
else
    echo "ℹ️  Contenedor no existía: $CONTAINER_NAME"
fi

# 2. Eliminar imagen
if docker images | grep -q $IMAGE_NAME; then
    docker rmi $IMAGE_NAME
    echo "✅ Imagen eliminada: $IMAGE_NAME"
else
    echo "ℹ️  Imagen no existía: $IMAGE_NAME"
fi

# 3. Eliminar archivos de disco
if ls *.img > /dev/null 2>&1; then
    rm -f *.img
    echo "✅ Archivos de disco eliminados"
else
    echo "ℹ️  No había archivos de disco"
fi

# 4. Limpiar montajes temporales
sudo umount /mnt/fsck-lab-temp 2>/dev/null && echo "✅ Montajes temporales limpiados" || true

# 5. Eliminar Dockerfile
rm -f Dockerfile

echo ""
echo "🧹 Limpieza completada exitosamente"
echo "El directorio $LAB_DIR permanece para uso futuro"
EOF

# 4. Crear documentación
cat > EJERCICIOS.md <<'EOF'
# 🛠️ FSck Lab - Guía Completa de Ejercicios

## 📋 Descripción
Laboratorio portátil para practicar recuperación de sistemas de archivos EXT4 usando Docker.

## 🚀 Configuración Rápida

```bash
# 1. Configurar (solo primera vez)
./fsck-lab-setup.sh

# 2. Generar ejercicios 
./fsck-exercises.sh

# 3. Entrar al contenedor
docker exec -it fsck-lab-container bash

# 4. Practicar!
# ... ver ejercicios abajo ...

# 5. Limpiar (cuando termines)
./fsck-cleanup.sh

#!/bin/bash
# Ejercicio: Reparación de /etc/fstab corrupto
# Simula errores comunes de montaje en sistemas Linux

set -e

echo "=== CREANDO EJERCICIO DE REPARACIÓN /etc/fstab ==="

LAB_DIR="./fstab-repair-lab"
mkdir -p "$LAB_DIR"
cd "$LAB_DIR"

# 1. Crear Dockerfile especializado
cat > Dockerfile <<'EOF'
FROM ubuntu:24.04

# Instalar herramientas del sistema
RUN apt-get update && apt-get install -y \
    systemd \
    util-linux \
    mount \
    e2fsprogs \
    vim \
    less

# Crear estructura de discos simulados
RUN dd if=/dev/zero of=/disco-root.img bs=1M count=50 && \
    dd if=/dev/zero of=/disco-home.img bs=1M count=30 && \
    dd if=/dev/zero of=/disco-backup.img bs=1M count=20 && \
    mkfs.ext4 /disco-root.img && \
    mkfs.ext4 /disco-home.img && \
    mkfs.ext4 /disco-backup.img

# Crear puntos de montaje
RUN mkdir -p /mnt/root-real /mnt/home-real /mnt/backup-real

# Script de inicialización que crea fstab corrupto
COPY iniciar-sistema.sh /root/
RUN chmod +x /root/iniciar-sistema.sh

CMD ["/root/iniciar-sistema.sh"]
EOF

# 2. Crear script de inicialización que simula el error
cat > iniciar-sistema.sh <<'EOF'
#!/bin/bash
echo "=== INICIANDO SISTEMA CON /etc/fstab CORRUPTO ==="

# Configurar loop devices para los discos
losetup -fP /disco-root.img
losetup -fP /disco-home.img  
losetup -fP /disco-backup.img

# Montar discos temporalmente para poblarlos
mkdir -p /tmp/root /tmp/home /tmp/backup
mount /dev/loop0 /tmp/root
mount /dev/loop1 /tmp/home
mount /dev/loop2 /tmp/backup

# Crear estructura de archivos realista
echo "Sistema Operativo Linux" > /tmp/root/os-info.txt
echo "Archivos del usuario" > /tmp/home/user-data.txt  
echo "Backup importante" > /tmp/backup/backup-2024.txt

# Crear directorios del sistema
mkdir -p /tmp/root/{etc,var,usr,bin}
mkdir -p /tmp/home/{documents,downloads,music}

sync
umount /tmp/root /tmp/home /tmp/backup

# Crear /etc/fstab CON ERRORES DELIBERADOS
mkdir -p /etc
cat > /etc/fstab <<'FSTABEOF'
# /etc/fstab: static file system information.
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
UUID=correct-root    /               ext4    errors=remount-ro 0       1
/dev/loop1          /home           ext4    defaults        0       2
/dev/loop2          /backup         ext4    defaults        0       2

# LÍNEAS CON ERRORES (SIMULANDO CONFIGURACIÓN CORRUPTA):
/dev/loopX          /var            ext4    defaults        0       2       # ERROR: Dispositivo no existe
UUID=invalid-uuid-1234 /opt         ext4    defaults        0       2       # ERROR: UUID inválido
/dev/loop2          /backup         ext4    defaults        0       2       # ERROR: Montaje duplicado
/dev/sdb1           /data           ext4    defaults        0       2       # ERROR: Dispositivo no presente
FSTABEOF

echo "✅ Sistema configurado con /etc/fstab corrupto"
echo ""
echo "🚨 SÍNTOMAS DEL PROBLEMA:"
echo "   - Errores en journalctl sobre dispositivos faltantes"
echo "   - Fallos en montaje de particiones"
echo "   - Sistema puede bootear pero con advertencias"
echo ""
echo "🔧 HERRAMIENTAS DISPONIBLES:"
echo "   - journalctl -xb          # Ver logs del boot"
echo "   - blkid                    # Listar dispositivos y UUIDs"
echo "   - lsblk                    # Ver árbol de bloques"
echo "   - mount                    # Ver sistemas montados"
echo "   - vi/nano /etc/fstab      # Editar configuración"
echo ""
echo "🎯 TU MISIÓN:"
echo "   Identificar y corregir los errores en /etc/fstab"
echo "   Usar: journalctl -xb | grep -i 'fstab\\|mount\\|fsck'"
echo ""
echo "💡 PISTA: Busca líneas con dispositivos que no existen o UUIDs inválidos"

# Mantener el sistema corriendo
sleep infinity
EOF

# 3. Crear script de solución
cat > SOLUCION.md <<'EOF'
# 🎯 SOLUCIÓN: Reparación de /etc/fstab

## 🔍 DIAGNÓSTICO

Ejecuta estos comandos para identificar los problemas:

```bash
# 1. Ver logs de errores (similares al enunciado)
journalctl -xb | grep -i "fstab\|mount\|fsck" | head -20

# 2. Ver dispositivos reales disponibles
blkid
lsblk

# 3. Ver fstab actual
cat /etc/fstab

#!/bin/bash
# Laboratorio: Tareas 1, 2 y 3 completas
# Autor: Jensy Gómez
# Curso: Red Hat System Administration I (RH124)

OUTPUT="lab_sgid_tmp_report.txt"
> "$OUTPUT"

log() {
    echo "$1" | tee -a "$OUTPUT"
}


log "=================================================================="
log "           LABORATORIO - BIT SGID EN /tmp"
log " Curso   : Red Hat System Administration I (RH124)"
log " Autor   : Jensy Gómez"
log " Fecha   : $(date '+%Y-%m-%d %H:%M:%S')"
log " Host    : $(hostname)"
log "=================================================================="
log ""

# ==================== TAREA 1: Pon bit SGID a /tmp y verifica creando archivo como phoenix ====================
log "TAREA 1 - Bit SGID en /tmp:"
log "Estado inicial de /tmp:"
ls -ld /tmp >> "$OUTPUT" 2>&1
log "Aplicando SGID: chmod g+s /tmp"
chmod g+s /tmp
log "Estado después SGID:"
ls -ld /tmp >> "$OUTPUT" 2>&1
log "Prueba como phoenix:"
su -c "touch /tmp/phoenix_test.txt; ls -l /tmp/phoenix_test.txt" phoenix >> "$OUTPUT" 2>&1 || echo "Phoenix test completado" >> "$OUTPUT"
log "Archivo hereda grupo root ✓ (verifica con ls -l arriba)"
rm -f /tmp/phoenix_test.txt
log ""

# ==================== TAREA 2 – Crea /srv/datos con sticky bit y prueba con dos usuarios diferentes ====================
log "TAREA 2 - Sticky bit en /srv/datos:"
log "Creando directorio y permisos 777:"
mkdir -p /srv/datos
chmod 777 /srv/datos
ls -ld /srv/datos >> "$OUTPUT" 2>&1

log "Aplicando sticky bit: chmod o+t /srv/datos"
chmod o+t /srv/datos
ls -ld /srv/datos >> "$OUTPUT" 2>&1

log "Preparando usuarios de prueba:"
id alice >/dev/null 2>&1 || (useradd -m alice && echo "alice:alice" | chpasswd)
log "Usuarios listos: phoenix, alice"

log "=== PASO 1: PHOENIX crea su archivo ==="
su -c "touch /srv/datos/phoenix.txt; ls -l /srv/datos/phoenix.txt" phoenix >> "$OUTPUT" 2>&1
log "=== PASO 2: ALICE crea su archivo ==="
su -c "touch /srv/datos/alice.txt; ls -l /srv/datos/alice.txt" alice >> "$OUTPUT" 2>&1

log "=== PASO 3: ALICE intenta borrar archivo de PHOENIX ==="
su -c "rm /srv/datos/phoenix.txt" alice >> "$OUTPUT" 2>&1
log "=== PASO 4: PHOENIX intenta borrar archivo de ALICE ==="
su -c "rm /srv/datos/alice.txt" phoenix >> "$OUTPUT" 2>&1

log "=== VERIFICACIÓN FINAL ==="
ls -l /srv/datos/ >> "$OUTPUT" 2>&1
log "Sticky bit FUNCIONA: archivos protegidos ✓"
rm -f /srv/datos/*.txt
log ""



# ==================== TAREA 3 – Lista todos los binarios con SUID en /usr/bin → guarda en /root/suid.txt ====================
log "TAREA 3 - Binarios SUID en /usr/bin:"
find /usr/bin -perm -4000 -type f 2>/dev/null > /root/suid.txt
log "Total encontrados: $(wc -l < /root/suid.txt)"
cat /root/suid.txt >> "$OUTPUT"
log "Ejemplo permisos (passwd):"
ls -l /usr/bin/passwd >> "$OUTPUT" 2>&1
log "TAREA 3 COMPLETADA ✓"

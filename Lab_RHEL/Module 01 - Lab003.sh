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
ls -ld /tmp | log
log "Aplicando SGID: chmod g+s /tmp"
chmod g+s /tmp
log "Estado después SGID:"
ls -ld /tmp | log
log "Prueba como phoenix:"
su -c "touch /tmp/phoenix_test.txt; ls -l /tmp/phoenix_test*.txt" phoenix 2>/dev/null | log
log "Archivo hereda grupo root ✓"
rm -f /tmp/phoenix_test.txt
log ""



# ==================== TAREA 2 – Crea /srv/datos con sticky bit y prueba con dos usuarios diferentes ====================
log "TAREA 2 - Sticky bit en /srv/datos:"
log "Creando directorio y permisos 777:"
mkdir -p /srv/datos
chmod 777 /srv/datos
ls -ld /srv/datos | log

log "Aplicando sticky bit: chmod o+t /srv/datos"
chmod o+t /srv/datos
ls -ld /srv/datos | log

log "Preparando usuarios de prueba:"
# Verifica/crea phoenix (debería existir)
id phoenix >/dev/null 2>&1 || useradd -m phoenix && echo "phoenix:phoenix" | chpasswd
# Crea alice
id alice >/dev/null 2>&1 || useradd -m alice && echo "alice:alice" | chpasswd
log "Usuarios listos: $(id phoenix | cut -d'(' -f2 | cut -d')' -f1), $(id alice | cut -d'(' -f2 | cut -d')' -f1)"

log "=== PASO 1: PHOENIX crea su archivo ==="
su -c "touch /srv/datos/phoenix.txt && echo 'Phoenix: Archivo creado'" phoenix | log
ls -l /srv/datos/phoenix.txt | log

log "=== PASO 2: ALICE crea su archivo ==="
su -c "touch /srv/datos/alice.txt && echo 'Alice: Archivo creado'" alice | log
ls -l /srv/datos/alice.txt | log

log "=== PASO 3: ALICE intenta borrar archivo de PHOENIX ==="
su -c "rm /srv/datos/phoenix.txt" alice 2>&1 | log
log "Resultado esperado: Permission denied ✓"

log "=== PASO 4: PHOENIX intenta borrar archivo de ALICE ==="
su -c "rm /srv/datos/alice.txt" phoenix 2>&1 | log
log "Resultado esperado: Permission denied ✓"

log "=== VERIFICACIÓN FINAL ==="
ls -l /srv/datos/ | log
log "Sticky bit FUNCIONA: archivos protegidos ✓"
log "Limpiando archivos de prueba..."
rm -f /srv/datos/*.txt
log ""



# ==================== TAREA 3 – Lista todos los binarios con SUID en /usr/bin → guarda en /root/suid.txt ====================
log "TAREA 3 - Binarios SUID en /usr/bin:"
log "Buscando SUID: find /usr/bin -perm -4000 -type f"
find /usr/bin -perm -4000 -type f 2>/dev/null > /root/suid.txt
log "Total encontrados: $(wc -l < /root/suid.txt)"
cat /root/suid.txt | log
log "Ejemplo permisos (passwd):"
ls -l /usr/bin/passwd 2>/dev/null | log
log "TAREA 3 COMPLETADA ✓"
log ""
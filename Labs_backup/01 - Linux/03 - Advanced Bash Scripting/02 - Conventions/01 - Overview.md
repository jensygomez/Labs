---
Curso: Advanced Bash Scripting
Modulo: Conventions
Tema: Overview
Fecha: 2004-05-13
Estado: completado
tags:
---
Las convenciones en Bash scripting son el equivalente a un estándar de codificación: establecen reglas consistentes de nomenclatura, indentación, comentarios y estructura que permiten que cualquier miembro del equipo pueda leer y entender el código sin fricciones. Esto es especialmente crítico en entornos empresariales donde múltiples administradores trabajan sobre los mismos scripts, y garantiza que el mantenimiento sea más rápido y los bugs menos frecuentes. El video proporciona sugerencias prácticas sobre cómo aplicar estas convenciones desde el inicio.

Las convenciones abarcan aspectos como nombres descriptivos para variables y funciones, uso consistente de espacios y tabulaciones, comentarios claros en secciones complejas, y estructura modular del código. Aplicar estas prácticas desde el principio no solo mejora la legibilidad, sino que también previene errores lógicos y facilita la depuración. En tu rol como futuro Sysadmin, estos estándares serán fundamentales cuando escribas scripts de automatización que otros administradores deban mantener.

**Ejemplo de convención básica:**

bash

```bash
#!/bin/bash
# Script: backup_sistema.sh
# Descripción: Realiza backup incremental del sistema
# Autor: Tu nombre
# Fecha: 2025-05-13

# Variables con nombres descriptivos
BACKUP_DIR="/mnt/backups"
LOG_FILE="/var/log/backup.log"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Función bien documentada
realizar_backup() {
    local origen="$1"
    local destino="$2"
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando backup..." >> "$LOG_FILE"
    rsync -av "$origen" "$destino" >> "$LOG_FILE" 2>&1
}

realizar_backup "/home" "$BACKUP_DIR/home_$TIMESTAMP"
```
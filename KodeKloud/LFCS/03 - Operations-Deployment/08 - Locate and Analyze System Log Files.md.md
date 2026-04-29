

# Locate and Analyze System Log Files  
  
#lfcs #linux #operations #logs #troubleshooting  #Operations-Deployments 
  
## 📌 Concepto  
  
Los logs del sistema registran eventos importantes como:  
- mensajes de estado  
- errores (errors)  
- advertencias (warnings)  
  
Son fundamentales para el troubleshooting y la auditoría del sistema.  
  
---  
  
## 📁 Ubicación de logs  
  
La mayoría de los logs se almacenan en:  
  
    /var/log

Ejemplos importantes:

-   /var/log/syslog
-   /var/log/auth.log
-   /var/log/kern.log

⚠️ Muchos archivos requieren privilegios de root para ser leídos.

----------

## 🔍 Análisis de logs

### Ver contenido

    less /var/log/syslog

### Buscar errores

    grep  -i error /var/log/syslog

### Monitoreo en tiempo real

    tail -f /var/log/syslog
    
    tail -F /var/log/syslog

-   `-f` → sigue el archivo
-   `-F` → sigue incluso si el archivo rota

----------

## 🔐 Logs de autenticación

Archivo clave:

    /var/log/auth.log

Permite ver:

-   usuarios que iniciaron sesión
-   intentos fallidos
-   tipo de autenticación

----------

## ⚙️ rsyslog

Servicio encargado de gestionar logs en sistemas tradicionales.

-   recoge logs del sistema
-   los guarda en `/var/log`

----------

## 🚀 journalctl (systemd)

Más moderno y eficiente que logs tradicionales.

### Ver logs generales

    journalctl

### Filtrar por servicio

    journalctl -u  ssh

### Ver en tiempo real

    journalctl -f

### Filtrar por nivel de error

    journalctl -p err

### Buscar texto

    journalctl -g  ssh

### Filtrar por fechas

journalctl -S  "2026-04-01"  -U  "2026-04-02"

-   `-S` → desde (start)
-   `-U` → hasta (until)

### Ver logs por boot

    journalctl -b  0  # boot actual  
    journalctl -b  -1  # boot anterior

----------

## 👤 Auditoría de usuarios

### Ver últimos logins

    last

### Ver intentos fallidos

    lastb

### Ver último login por usuario

    lastlog

Permite ver:

-   usuario
-   fecha de login
-   IP de origen

----------

## 🔍 Troubleshooting

-   Buscar errores con `grep`
-   Monitorear servicios con `journalctl -u`
-   Revisar autenticaciones sospechosas en `auth.log`
-   Usar `tail -F` para debugging en tiempo real



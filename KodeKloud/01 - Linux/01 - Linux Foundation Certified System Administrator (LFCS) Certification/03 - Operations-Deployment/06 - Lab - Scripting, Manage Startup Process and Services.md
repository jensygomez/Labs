---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Tema: Lab - Scripting, Manage Startup Process and Services
Fecha de Inicio: 2026-05-15
Dificultad: Intermedio-Medio
Tareas Totales: "14"
tags:
  - Linux
  - Linux/LFCS-Certification
  - Linux/LFCS-Certification/Essential-Commands
  - Linux/LFCS-Certification/Essential-Commands/Lab-Scripting-Process-Services
  - Linux/LFCS-Certification/Essential-Commands/Lab-Scripting-Process-Services/Laboratorio
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 15 - 05 - 2026 | 40 min | 35 %  |               |
|                |        |       |               |


# 📚 Scripting y Gestión de Servicios Systemd

Este laboratorio se enfoca en dominar la creación de scripts bash y la administración de servicios systemd en Linux. A través de 14 tareas progresivas, aprendes a manipular archivos de servicio, configurar el comportamiento de reinicio, crear scripts ejecutables y gestionar el estado de servicios críticos como SSH y Apache2. Las tareas incluyen desde la edición de archivos systemd y corrección de directivas (como RestartPolicy y After), hasta la creación de scripts que interactúen con el sistema de servicios y la configuración del sistema de arranque.

El laboratorio cubre conceptos esenciales para un Sysadmin: entender shebangs, permisos de ejecución, gestión de PIDs, archivos tar.gz, targets de boot (graphical vs text), y la programación de apagados del sistema. Dominar estos conceptos es crítico para administrar servidores Linux en producción, especialmente en la automatización de tareas y la resolución de problemas de arranque y servicios.

## 💡 Comandos de Ejemplo

```bash
# Ver estado completo de un servicio
systemctl status sshd.service

# Encontrar archivo de servicio y editarlo
find / -name kkloud.service 2>/dev/null
sudo systemctl edit kkloud.service

# Mask/Unmask de servicios
sudo systemctl mask apache2.service
sudo systemctl unmask apache2.service

# Crear script ejecutable con shebang
#!/bin/bash
chmod +x script.sh
./script.sh

# Programar apagado en 2 horas
sudo shutdown -h +120

# Cambiar target de boot (graphical)
sudo systemctl set-default graphical.target
sudo systemctl get-default
```

## 🎯 Conceptos Clave a Retener

- **Shebang**: `#!/bin/bash` es obligatorio al inicio de scripts
- **RestartPolicy**: Cambiar de `on-failure` a `always` para reinicio incondicional
- **ExecStop**: Define el comando exacto para detener el servicio
- **After**: Define dependencias de arranque entre servicios
- **Mask/Unmask**: Prevenir o permitir que un servicio se inicie
- **Systemd targets**: `graphical.target` (GUI) vs `multi-user.target` (CLI)

---
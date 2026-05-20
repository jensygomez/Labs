---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Lab - Manage System-Wide Environment Profiles
Fecha de Inicio: 2001-04-20
Dificultad: Básico Medio
Tareas Totales: "12"
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 20 - 04 - 2026 | 20 min | 33 %  |               |
| 17 - 05 -2026  | 35 min | 33 %  |               |

[[Laboratorios del LFCS]]

---

El laboratorio se enfocó en comprender cómo funcionan las variables de entorno en Linux y su gestión a nivel del sistema. Se cubrieron conceptos clave como la visualización de variables (echo $VAR), la distinción entre variables locales y globales, y cómo archivos críticos como `/etc/environment` permiten establecer variables disponibles para todos los usuarios. También se exploró el directorio `/etc/skel`, que actúa como plantilla de donde se copian archivos a la home de nuevos usuarios al momento de su creación.

La segunda parte del lab se enfocó en la configuración de perfiles de usuario y automatización de procesos. Se aprendió a modificar archivos de configuración del sistema para ejecutar comandos automáticamente al login (como mensajes de bienvenida), personalizar el PATH para usuarios específicos agregando directorios personalizados, y cómo implementar archivos README automáticos en nuevas cuentas usando `/etc/skel`. Estos conceptos son fundamentales para la administración consistente de entornos multi-usuario en servidores.

**Comandos ejemplo:**

bash

```bash
# Ver todas las variables de entorno del usuario actual
env > /home/bob/env

# Establecer variable global para todos los usuarios
echo 'GLOBALOPTION=ON' >> /etc/environment

# Agregar comando de bienvenida al login
echo 'echo Welcome to our server!' >> /etc/profile

# Copiar plantillas a nuevo usuario
cp /etc/skel/* /home/bob/default_data/

# Modificar PATH para un usuario
echo 'export PATH=$PATH:$HOME/.config/bin' >> /home/bob/.bashrc
```
---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Tema: Lab - Manage System-Wide Environment Profiles
Fecha de Inicio: 2001-04-20
Dificultad: Básico Medio
Tareas Totales: "12"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `20/04/2026` | 20 min | 0 %   |               |
| `17/05/2026` | 35 min | 33 %  |               |
| `27/05/2026` |        |       |               |
|              |        |       |               |

[[Laboratorios del LFCS]]

---





**Comandos ejemplo:**



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
---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Configure SSH Servers and Clients
Typo: Video
Fecha: 06/05/2026
Estado: completado
Dificultad: Intermedio-Baja
Calificación:
Time: 30 min
tags:
  - "#Linux/LFCS-Certification/Networking"
  - "#Linux/LFCS-Certification/Networking/ssh"
  - "#Linux/LFCS-Certification/Networking/Cryptografy"
  - "#Linux/LFCS-Certification/Networking/Authentication"
---
SSH (Secure Shell) es el protocolo estándar para acceso remoto seguro en Linux. La configuración del servidor SSH se realiza en `/etc/ssh/sshd_config` (donde la 'd' indica daemon), mientras que la del cliente se maneja sin la 'd'. Los parámetros críticos incluyen Port (puerto de escucha), AddressFamily, ListenAddress (para restringir conexiones a IPs específicas), PermitRootLogin, PasswordAuthentication, KbdInteractiveAuthentication y X11Forwarding. También es posible configurar reglas por usuario con directivas Per-user para personalizar accesos según necesidades específicas.

Para optimizar la conexión a múltiples servidores, se configura el archivo `~/.ssh/config` en el cliente con hosts predefinidos. La autenticación basada en clave pública es más segura que contraseñas: se genera un par de claves con `ssh-keygen`, se copia la clave pública al servidor remoto, y se mantiene la privada protegida localmente. Después de cualquier cambio en la configuración del servidor, es necesario recargar el servicio SSH para aplicar los cambios.

**Ejemplo de comandos básicos:**

bash

```bash
# Ver y editar configuración del servidor SSH
sudo vim /etc/ssh/sshd_config

# Recargar el servicio SSH después de cambios
sudo systemctl reload ssh.service

# Generar par de claves SSH
ssh-keygen -t rsa -b 4096

# Copiar clave pública al servidor (método automático)
ssh-copy-id -i ~/.ssh/id_rsa.pub user@servidor.com

# Conectar a servidor usando clave específica
ssh -i ~/.ssh/id_rsa user@servidor.com

# Editar configuración del cliente SSH
vim ~/.ssh/config

# Verificar conexión SSH
ssh -vv user@servidor.com
```
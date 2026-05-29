---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Lab - Configure SSH Servers and Clients
Fecha de Inicio: 2026-04-20
Dificultad: Intermedio-Baja
Tareas Totales: "12"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `20/04/2026` | 40 min | 9 %   |               |
| `19/05/2026` | 45 min | 16 %  |               |
| `29/05/2026` |        |       |               |

[[Laboratorios del LFCS]]

---















## Comandos de ejemplo

```bash
# Editar configuración SSH Server
sudo nano /etc/ssh/sshd_config

# Verificar y aplicar cambios
sudo sshd -t  # Test de sintaxis
sudo systemctl restart sshd

# Editar configuración SSH Client
sudo nano /etc/ssh/ssh_config

# Instalar y habilitar Squid
sudo dnf install squid -y
sudo systemctl start squid
sudo systemctl enable squid

# Editar configuración Squid
sudo nano /etc/squid/squid.conf

# Recargar configuración Squid
sudo systemctl reload squid
```


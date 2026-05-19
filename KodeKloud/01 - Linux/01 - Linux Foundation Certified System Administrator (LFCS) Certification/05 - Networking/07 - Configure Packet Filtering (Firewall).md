---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Configure Packet Filtering (Firewall)
Typo: Video
Fecha: 04/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 30 min
tags:
  - "#Linux/LFCS-Certification/Networking"
---


## Configuración de Packet Filtering con UFW

**UFW (Uncomplicated Firewall)** es la herramienta estándar en Ubuntu para gestionar reglas de firewall de forma simplificada. Su filosofía es mantener todo bloqueado por defecto y, únicamente, otorgar acceso explícito a los puertos y servicios necesarios. Al activar UFW con `sudo ufw enable`, el servidor se cierra completamente. Desde ese punto, se deben ir creando reglas permisivas para permitir el tráfico deseado. Por ejemplo, `sudo ufw allow 22` permite conexiones SSH y es la primera regla crítica para no perder acceso remoto. Una vez configuradas las reglas básicas, es posible verificar el estado y las conexiones activas con `sudo ufw status` y `ss -tn` para ver qué tráfico efectivamente está llegando al servidor.

La potencia de UFW radica en su granularidad: es posible crear reglas específicas por interfaz de red, rango de IPs, puertos, y protocolos. Por ejemplo, `sudo ufw allow from 10.0.0.0/24 to any port 22` restringe SSH únicamente a la subred 10.0.0.0/24, o `sudo ufw deny from 10.0.0.37` rechaza todo tráfico de una IP específica. Las reglas de negación se pueden insertar en posiciones específicas con `sudo ufw insert 1 deny from IP`, lo que permite prioridades. En configuraciones avanzadas con múltiples interfaces de red, es posible ser muy preciso: `sudo ufw allow in on enp0s3 from 10.0.0.192 to 10.0.0.100 proto tcp` solo permite tráfico TCP desde esa IP específica hacia ese destino en la interfaz enp0s3.

### Ejemplos de Comandos

```bash
# Activar UFW y habilitar al inicio
sudo ufw enable
sudo ufw status

# Permitir SSH (critico antes de activar)
sudo ufw allow 22

# Permitir desde una subred específica
sudo ufw allow from 10.0.0.0/24 to any port 22

# Denegar una IP específica
sudo ufw deny from 10.0.0.37

# Insertar regla en posición específica
sudo ufw insert 1 deny from 10.0.0.37

# Regla granular por interfaz, IP origen, destino y protocolo
sudo ufw allow in on enp0s3 from 10.0.0.192 to 10.0.0.100 proto tcp

# Bloquear tráfico saliente hacia una IP específica
sudo ufw deny out on enp0s3 to 8.8.8.8

# Ver conexiones activas
ss -tn
```

---


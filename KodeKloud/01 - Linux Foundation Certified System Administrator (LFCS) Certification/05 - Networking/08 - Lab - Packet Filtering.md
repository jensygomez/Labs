---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Lab - Packet Filtering
Typo: Laboratorio
Fecha: 05/05/2026
Estado: completado
Dificultad: Intermedio-Baja
Calificación: 40 %
Time: 20 min
tags:
  - "#Linux/LFCS-Certification/Networking"
  - "#Linux/LFCS-Certification/Networking/Laboratorio"
  - "#Linux/LFCS-Certification/Networking/Iptables"
  - "#Linux/LFCS-Certification/Networking/Firewall"
  - "#Linux/LFCS-Certification/Networking/UFW"
  - "#Linux/LFCS-Certification/Networking/Security"
  - "#Linux/LFCS-Certification/Networking/Packet-filtering"
---


## Resumen

El laboratorio de Packet Filtering con UFW (Uncomplicated Firewall) se enfoca en la configuración correcta de reglas de cortafuegos en Linux. El concepto clave es entender el orden de evaluación de las reglas: UFW procesa las reglas de forma secuencial y se detiene en la primera coincidencia, por lo que una regla restrictiva después de una permisiva nunca se ejecutará. Durante este lab se configuraron reglas para permitir tráfico específico (SSH puerto 22, HTTP puerto 80, DNS puerto 53 TCP) y desde direcciones IP concretas, además de aprender a identificar y corregir errores de posicionamiento de reglas que impiden el funcionamiento esperado del firewall.

La importancia de este laboratorio radica en desarrollar la capacidad de troubleshooting en configuraciones de firewall, un skill crítico para cualquier administrador de sistemas. Se aprende que las reglas deben ordenarse lógicamente: primero las excepciones específicas y luego las reglas generales, evitando que reglas restrictivas sean enmascaradas por reglas permisivas anteriores. Este conocimiento es fundamental para mantener la seguridad de un servidor sin bloquear servicios legítimos.

## Ejemplos de comandos

```bash
# Habilitar UFW y permitir SSH (paso inicial crítico)
sudo ufw enable
sudo ufw allow 22/tcp

# Permitir tráfico HTTP
sudo ufw allow 80/tcp

# Permitir tráfico DNS sobre TCP
sudo ufw allow 53/tcp

# Permitir todo tráfico desde una IP específica
sudo ufw allow from 207.45.232.181

# Listar todas las reglas numeradas
sudo ufw status numbered

# Eliminar una regla por número (si está mal posicionada)
sudo ufw delete 5

# Reinsertar una regla en posición correcta
sudo ufw insert 1 deny from 10.0.0.19
```

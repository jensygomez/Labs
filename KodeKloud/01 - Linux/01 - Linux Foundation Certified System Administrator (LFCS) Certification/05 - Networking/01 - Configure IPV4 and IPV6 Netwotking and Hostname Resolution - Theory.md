---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Tema: Configure IPV4 and IPV6 Netwotking and Hostname Resolution - Theory
Typo: Video
Fecha: 03/05/2026
Estado: completado
Dificultad: Básico Medio
Calificación:
Time: 10 min
tags:
---
El protocolo **IPv4** es el estándar más utilizado en redes modernas, compuesto por 4 octetos de 8 bits cada uno (rango 0-255 por octeto), lo que genera un total de 32 bits. La estructura se complementa con una máscara de red que determina qué porción de la dirección pertenece a la red y cuál al host. La notación CIDR (/24, /16, /32) simplifica la representación de estas máscaras y es fundamental para entender subnetting y determinar si dos hosts pertenecen a la misma red o no.

**IPv6** representa la evolución necesaria del protocolo, utilizando 128 bits organizados en 8 grupos de 4 dígitos hexadecimales cada uno, permitiendo un espacio de direcciones vastamente superior. Las reglas de compresión de IPv6 permiten omitir grupos de ceros consecutivos (::) y acortar los ceros líderes en cada grupo, resultando en direcciones más legibles y eficientes. Aunque IPv4 sigue siendo predominante, IPv6 es inevitable en infraestructuras modernas.

**Ejemplo de comando:**

bash

```bash
# Ver configuración de red IPv4
ip addr show

# Verificar ruta de red
ip route show

# Ejemplo de notación CIDR - Subred /24
# 192.168.1.0/24 = 256 direcciones (0-255)
```
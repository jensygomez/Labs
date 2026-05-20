---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: "Use Network Block Devices: NBD"
Typo: Video
Fecha: 2026-05-09
Estado: completado
Dificultad: Básico Medio
Calificación:
Tareas del Lab:
Time: 15 min
---

## Network Block Devices (NBD) Overview

NBD es una tecnología que permite exponer un dispositivo de bloque (como una partición o imagen de disco) sobre la red, funcionando de manera similar a iSCSI pero con menos overhead. La arquitectura es simple: un servidor NBD comparte un recurso de almacenamiento a través de la red, y clientes remotos pueden montarlo como si fuera un dispositivo local. Esto es especialmente útil en entornos virtualizados, clusters de almacenamiento o cuando necesitas acceso de bajo nivel a bloques de almacenamiento sin la complejidad de soluciones empresariales más pesadas.

La configuración es straightforward: en el servidor instalas `nbd-server` y defines qué recursos compartir en `/etc/nbd-server/config.d`, mientras que en el cliente cargas el módulo del kernel `nbd` y te conectas al servidor remoto. Una vez conectado, el cliente ve el dispositivo como `/dev/nbd0` o similar, permitiendo operaciones de bloque nativos. Este enfoque proporciona baja latencia y es ideal para escenarios donde necesitas control a nivel de bloque con acceso remoto en redes LAN confiables.

## Configuración Servidor-Cliente

**Servidor:**
```bash
# Instalar NBD Server
sudo apt install nbd-server

# Editar configuración
sudo vi /etc/nbd-server/config.d/exports

# Iniciar servicio
sudo systemctl start nbd-server
sudo systemctl enable nbd-server
```

**Cliente:**
```bash
# Instalar NBD Client
sudo apt install nbd-client

# Cargar módulo del kernel
sudo modprobe nbd

# Conectar al servidor NBD
sudo nbd-client 127.0.0.1 -N partition2 /dev/nbd0

# Verificar conexión
lsblk | grep nbd
```
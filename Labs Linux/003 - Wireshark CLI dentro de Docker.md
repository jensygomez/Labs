# 🧠 Wireshark CLI dentro de Docker (Ubuntu)

## 🎯 Objetivo
Practicar la captura y análisis de tráfico de red utilizando **tcpdump** (Wireshark en línea de comandos) dentro de un contenedor **Docker Ubuntu**, sin afectar el sistema principal.

---

## 🧩 Requisitos previos

- Tener **Docker** instalado y funcionando (`docker --version`)
- Conexión a Internet
- Permisos para ejecutar comandos `sudo`

---

## 🚀 Paso 1: Crear el contenedor de laboratorio

Ejecuta en tu terminal (fuera del contenedor):

    docker run -it --name lab_wireshark --cap-add=NET_ADMIN ubuntu:22.04 bash
## ⚙️ Paso 2: Actualizar e instalar herramientas dentro del contenedor

Dentro del contenedor (verás algo como `root@<id>:/#`):

    apt update

    apt install -y tcpdump iproute2 iputils-ping net-tools curl` 

> Esto instalará las herramientas necesarias para realizar pruebas de red y capturas de paquetes.

----------

## 🌐 Paso 3: Verificar conectividad

Prueba tu conexión de red:

    ping -c 3 8.8.8.8

Si recibes respuestas, el contenedor tiene acceso a Internet.

----------

## 🧪 Paso 4: Capturar tráfico en tiempo real (modo Wireshark CLI)

    tcpdump -i any -n

🔹 `-i any` = captura en todas las interfaces  
🔹 `-n` = muestra IPs en lugar de nombres DNS

Para detener la captura, presiona **Ctrl + C**.

----------

## 💾 Paso 5: Guardar una captura en archivo `.pcap`

Captura tráfico y guárdalo para analizar después:

    tcpdump -i any -n -w capture.pcap

Mientras `tcpdump` está corriendo, genera tráfico, por ejemplo:

    curl http://example.com 

Luego detén `tcpdump` con **Ctrl + C**.

----------

## 📂 Paso 6: Copiar la captura al host

Desde otra terminal en tu host Linux:

    docker cp lab_wireshark:/capture.pcap . 

Ahora tendrás el archivo **capture.pcap** en tu máquina local.  
Puedes abrirlo con **Wireshark GUI** si lo prefieres.

----------

## 🧰 Paso 7: Reutilizar el laboratorio más adelante

Para **salir del contenedor** sin eliminarlo:

`exit` 

Y cuando desees volver a practicar:

`docker start -ai lab_wireshark` 

Esto conserva tus capturas y configuraciones para futuras sesiones.

----------

## 🧼 (Opcional) Limpiar el laboratorio

Si deseas eliminarlo completamente:

`docker rm -f lab_wireshark`








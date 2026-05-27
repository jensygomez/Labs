---
Curso: Shell Scripts for Beginners
Modulo: Project - KodeKloud e-commerce application
Tema: Lab - Project
Fecha: 2026-05-13
tags:
---
Este laboratorio implementa una aplicación e-commerce funcional en un servidor CentOS/Rocky Linux. Se configura un stack LAMP (Linux, Apache, MySQL/MariaDB, PHP) integrando firewall, base de datos con tabla de productos y un servidor web con variables de entorno. El objetivo es practicar la instalación y configuración de servicios críticos en Linux, manejo de permisos de firewall, y conexión entre capas de aplicación.

La práctica incluye crear usuarios de base de datos, cargar datos de inventario con scripts SQL, clonar código desde repositorio Git, y configurar variables de entorno en un archivo .env para la conexión segura entre PHP y MariaDB. Se refuerzan conceptos de systemd para gestionar servicios, firewall-cmd para reglas de tráfico, y la estructura básica de una aplicación web multi-capa en Linux.

**Ejemplo de comando clave:**

bash

```bash
# Crear la base de datos y usuario con privilegios
sudo mysql -e "CREATE DATABASE ecomdb; CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword'; GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost'; FLUSH PRIVILEGES;"

# Cargar los datos de productos
sudo mysql < db-load-script.sql

# Clonar la aplicación
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/
```
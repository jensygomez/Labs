#!/bin/bash
# ============================================================================
# PROYECTO: Automatización de Golden Base Image (Rocky Linux 9.7)
# SCRIPT:   3 de 5 - Despliegue de Servicios Web y Capa de Gestión
# ============================================================================
#
# DESCRIPCIÓN:
#   Este script aprovisiona la lógica de aplicación inicial sobre la red 
#   construida en el Script 2. Se centra en establecer el servidor web 
#   en la sede de Alemania y validar la visibilidad desde China y SysAdmin.
#
# OBJETIVOS TÉCNICOS:
#   1. Instalar y configurar Nginx como servidor nativo.
#   2. Desplegar contenido web corporativo en el segmento SRV-1 (10.10.0.10).
#   3. Configurar el entorno de gestión para el nodo ADM-1 (Home Office).
#   4. Preparar el sistema para las pruebas de conectividad de Capa 7 (HTTP).
#
# ARQUITECTURA ACTIVA EN ESTE MÓDULO:
#   - Origen: NS-CLI-1 (China) ----> Destino: NS-SRV-1 (Alemania:80)
#   - Gestión: NS-ADM-1 (Admin) ---> Control Total sobre la Infraestructura.
#
# CONSIDERACIONES DE TROUBLESHOOTING PARA JUNIORS:
#   - Los servicios NO corren en el Host principal; corren dentro de Namespaces.
#   - Para verificar puertos abiertos, usar: ip netns exec NS-SRV-1 ss -ntlp
#   - Los logs de acceso se encuentran en la ruta estándar, pero filtrados
#     por la configuración específica de este laboratorio.
#
# REQUISITOS PREVIOS:
#   - Script 2 ejecutado y persistente (Interfaces br- y Namespaces NS-).
#   - Conectividad de Capa 3 (ICMP/Ping) verificada entre nodos.
# ============================================================================

set -e
set -e

echo "=== 🖥️  SCRIPT 3: DESPLEGANDO SERVICIOS INICIALES (WEB/ADMIN) ==="

# 1. Instalación de paquetes en el Host
echo "📦 Instalando Nginx..."
dnf install -y nginx

# 2. Configuración de la página web nativa (Alemania - SRV-1)
echo "🌐 Configurando contenido web para Alemania..."
mkdir -p /var/www/html/alemania
cat > /var/www/html/alemania/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Sede Central - Alemania</title>
    <style>
        body { font-family: sans-serif; text-align: center; background: #2c3e50; color: white; padding: 50px; }
        .status { background: #27ae60; padding: 10px; border-radius: 5px; display: inline-block; }
    </style>
</head>
<body>
    <h1>🇩🇪 Bienvenidos a la Sede Central (Alemania)</h1>
    <div class="status">SISTEMA OPERATIVO</div>
    <p>Accediendo desde la IP: 10.10.0.10</p>
    <hr>
    <p><small>Golden Image Lab - Entrenamiento para Juniors/Plenos</small></p>
</body>
</html>
EOF

# 3. Configuración de Nginx para correr dentro del Namespace
# Creamos un config file específico que no use los puertos estándar del host
cat > /etc/nginx/conf.d/alemania.conf << 'EOF'
server {
    listen 10.10.0.10:80;
    server_name _;
    root /var/www/html/alemania;
    index index.html;
}
EOF

# 4. Ajuste de permisos para evitar errores de Nginx
chmod -R 755 /var/www/html/alemania
chown -R nginx:nginx /var/www/html/alemania

# 5. LANZADOR DE SERVICIOS (Lab Control)
# Este script es el que el Junior usará para "subir la palanca"
cat > /usr/local/bin/lab-start-services << 'EOF'
#!/bin/bash
echo "🚀 Iniciando Nginx en NS-SRV-1..."
# Ejecutamos Nginx dentro del namespace de Alemania
ip netns exec NS-SRV-1 nginx -g "daemon off;" &
echo "✅ Servicios web activos."
EOF
chmod +x /usr/local/bin/lab-start-services

echo "===================================================="
echo "🏆 CAPA WEB LISTA"
echo "Para iniciar la web ejecuta: lab-start-services"
echo "Desde China prueba con: ip netns exec NS-CLI-1 curl 10.10.0.10"
echo "===================================================="
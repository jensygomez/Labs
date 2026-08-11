#!/bin/bash
# lab-inc007.sh - Preparación completa del incidente INC-007 en un solo archivo

echo "======================================================================"
echo "🚀 PREPARANDO LABORATORIO INC-007: Errores 502 Intermitentes"
echo "======================================================================"

# ==========================================
# PASO 1: Crear 4 VMs (server01-04)
# ==========================================
echo ""
echo "📦 Paso 1: Creando 4 servidores..."
for i in {1..4}; do
    NODE="server0$i"
    if ! lxc info $NODE &>/dev/null; then
        echo "   → Creando $NODE..."
        lxc launch images:almalinux/9 $NODE --profile default
    else
        echo "   → $NODE ya existe."
    fi
done

echo "⏳ Esperando 20s a que arranquen y obtengan IPs por DHCP..."
sleep 20

# ==========================================
# PASO 2: Detectar IPs y generar inventory.ini
# ==========================================
echo ""
echo "🌐 Paso 2: Detectando IPs asignadas por DHCP..."

cat > inventory.ini << 'EOF'
[all:vars]
ansible_user=root
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

EOF

for i in {1..4}; do
    NODE="server0$i"
    IP=$(lxc list -c n4 --format csv | grep "^$NODE," | awk -F',' '{print $2}' | awk '{print $1}')
    
    if [ -z "$IP" ]; then
        echo "   ❌ ERROR: No se pudo obtener IP de $NODE"
        exit 1
    fi
    
    echo "   ✅ $NODE: $IP"
    
    if [ $i -eq 4 ]; then
        echo "server0$i ansible_host=$IP" >> inventory.ini
        echo "" >> inventory.ini
        echo "[backend_api]" >> inventory.ini
        echo "server0$i" >> inventory.ini
    else
        echo "server0$i ansible_host=$IP" >> inventory.ini
    fi
done

echo "" >> inventory.ini
echo "[frontend_fleet]" >> inventory.ini
echo "server01" >> inventory.ini
echo "server02" >> inventory.ini
echo "server03" >> inventory.ini

# ==========================================
# PASO 3: Instalar paquetes mínimos
# ==========================================
echo ""
echo "📦 Paso 3: Instalando paquetes (nginx, python3, curl)..."
for i in {1..4}; do
    NODE="server0$i"
    echo "   → Instalando en $NODE..."
    lxc exec $NODE -- dnf install -y nginx python3 curl firewalld >/dev/null 2>&1
    lxc exec $NODE -- systemctl enable --now nginx firewalld >/dev/null 2>&1
done

# ==========================================
# PASO 4: Configurar Backend en server04
# ==========================================
echo ""
echo "🔧 Paso 4: Configurando backend lento en server04..."
BACKEND_IP=$(grep "server04" inventory.ini | awk '{print $2}' | cut -d'=' -f2)

lxc exec server04 -- bash -c "cat > /opt/backend_api.py << 'EOF'
import http.server, socketserver, time, random

class SlowHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        time.sleep(random.uniform(0.5, 2.5))
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'OK\n')

if __name__ == '__main__':
    with socketserver.TCPServer(('', 8080), SlowHandler) as httpd:
        httpd.serve_forever()
EOF"

lxc exec server04 -- bash -c "cat > /etc/systemd/system/backend-api.service << 'EOF'
[Unit]
Description=Slow Backend API
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/backend_api.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

lxc exec server04 -- systemctl daemon-reload
lxc exec server04 -- systemctl enable --now backend-api
lxc exec server04 -- firewall-cmd --add-port=8080/tcp --permanent
lxc exec server04 -- firewall-cmd --reload

# ==========================================
# PASO 5: Configurar Nginx en server01-03
# ==========================================
echo ""
echo "🔧 Paso 5: Configurando Nginx reverse proxy en server01-03..."

for i in {1..3}; do
    NODE="server0$i"
    
    lxc exec $NODE -- bash -c "cat > /etc/nginx/conf.d/backend_proxy.conf << EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://$BACKEND_IP:8080;
        proxy_read_timeout 5s;
        proxy_connect_timeout 2s;
    }
}
EOF"
    
    lxc exec $NODE -- systemctl reload nginx
    lxc exec $NODE -- firewall-cmd --add-service=http --permanent
    lxc exec $NODE -- firewall-cmd --reload
done

# ==========================================
# PASO 6: Inyectar el fallo en server03
# ==========================================
echo ""
echo "💥 Paso 6: Inyectando fallo en server03 (proxy_read_timeout 1s)..."

lxc exec server03 -- bash -c "cat > /etc/nginx/conf.d/backend_proxy.conf << EOF
server {
    listen 80;
    server_name _;
    location / {
        proxy_pass http://$BACKEND_IP:8080;
        proxy_read_timeout 1s;
        proxy_connect_timeout 2s;
    }
}
EOF"

lxc exec server03 -- systemctl reload nginx

# ==========================================
# PASO 7: Poner el ticket MOTD en todas las VMs
# ==========================================
echo ""
echo "🎫 Paso 7: Desplegando ticket de incidente en /etc/motd..."

TICKET='======================================================================
OPS-1070 - INCIDENTE - PRIORIDAD 2
======================================================================
REPORTADO POR: API Gateway / Zabbix      HORA: 14:22 PM
RESUMEN: Errores intermitentes 502 Bad Gateway en la API de backend
======================================================================
DESCRIPCIÓN:
El gateway externo reporta errores 502 intermitentes al enrutar 
tráfico a nuestra flota de frontend (server01 a server03). 
El servicio backend está en server04 y es alcanzable, pero los 
clientes experimentan fallos aleatorios (tasa de error ~30-40%).

NOTAS DEL TURNO NOCTURNO (Nivel 1):
"Revisé server04. CPU y memoria están bien, el servicio corre. 
Reinicié el proceso backend por si acaso. Corrí mtr desde los 
nodos frontend a server04 y vi 0% de pérdida de paquetes. 
Revisé logs de Nginx en server01 y server02 y estaban limpios. 
Cierro como No se puede reproducir, parece un fallo de red 
transitorio o problema del cliente."

IMPACTO: Usuarios finales experimentan fallos en la UI y envíos de formularios.
======================================================================'

for i in {1..4}; do
    NODE="server0$i"
    lxc exec $NODE -- bash -c "echo '$TICKET' > /etc/motd"
done

# ==========================================
# PASO 8: Verificación final
# ==========================================
echo ""
echo "======================================================================"
echo "✅ LABORATORIO INC-007 LISTO"
echo "======================================================================"
echo ""
echo "📋 Resumen:"
echo "   - Backend lento: server04 ($BACKEND_IP:8080)"
echo "   - Frontend sano: server01, server02"
echo "   - Frontend culpable: server03 (timeout 1s)"
echo ""
echo "🎯 Tu misión:"
echo "   1. Entra a cualquier servidor: lxc exec server01 -- bash"
echo "   2. Lee el ticket: cat /etc/motd"
echo "   3. Reproduce el error: for i in {1..10}; do curl -s -o /dev/null -w '%{http_code}\n' http://localhost/; done"
echo "   4. Diagnostica y resuelve el incidente"
echo ""
echo "🔍 Pista: Compara la configuración de Nginx entre los 3 frontends"
echo "======================================================================"

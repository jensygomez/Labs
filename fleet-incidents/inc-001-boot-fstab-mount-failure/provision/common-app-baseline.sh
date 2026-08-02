#!/usr/bin/env bash
# common-app-baseline.sh
# Corre IGUAL en node01, node02 y node03 — sano o afectado, todos arrancan
# con exactamente esta base. La diferencia (si la hay) la agrega gremlin/inject.sh
# DESPUÉS, en un provisioner separado.

set -o errexit
set -o pipefail

echo "==> Baseline: creando estructura de datos de la app..."

mkdir -p /data/app
cat > /data/app/status <<EOF
APP_VERSION=2.4.1
LAST_SUCCESSFUL_DEPLOY=2024-01-15T14:30:00Z
DB_CONNECTION_POOL=active
CACHE_SIZE=512MB
EOF
chown -R vagrant:vagrant /data/app 2>/dev/null || true

echo "==> Baseline: creando app-backend.service..."

cat > /etc/systemd/system/app-backend.service <<'EOF'
[Unit]
Description=Critical App Backend
RequiresMountsFor=/data
After=local-fs.target

[Service]
Type=simple
ExecStart=/bin/bash -c 'if [ -f "/data/app/status" ]; then echo "[$(date)] App started successfully" >> /data/app/status; sleep infinity; else echo "FATAL: /data/app/status not found" >&2; exit 1; fi'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "==> Baseline: creando legacy-daemon.service (false negative preexistente)..."

mkdir -p /opt/legacy
cat > /opt/legacy/start.sh <<'EOF'
#!/bin/bash
# Daemon legacy con bug conocido (OPS-891) — falla y reinicia en loop
# SIN relación con el incidente actual. Existe para practicar descarte
# de ruido, no es parte de la causa raíz.
echo "legacy-daemon: simulando fallo conocido..."
exit 1
EOF
chmod +x /opt/legacy/start.sh

cat > /etc/systemd/system/legacy-daemon.service <<'EOF'
[Unit]
Description=Legacy Monitoring Daemon (known issue OPS-891)

[Service]
Type=simple
ExecStart=/opt/legacy/start.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now legacy-daemon.service || true
systemctl enable --now app-backend.service || true

echo "==> Baseline completo en $(hostname)."

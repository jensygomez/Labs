#!/usr/bin/env bash
# storage-baseline.sh — node04
# Rol fijo en TODOS los labs de esta serie: nodo de storage compartido.
# En este incidente puntual (nivel 3, nodo único) no participa del fallo,
# pero está presente en la topología para que la descartes como parte
# del proceso de triage — en producción real, "quién NO está fallando"
# también es información.

set -o errexit
set -o pipefail

echo "==> node04: baseline de storage (sano, sin rol activo en inc-001)"

mkdir -p /srv/shared
echo "storage node — inc-001-boot-fstab-mount-failure" > /srv/shared/README.txt
chown -R vagrant:vagrant /srv/shared 2>/dev/null || true

echo "==> node04 listo."

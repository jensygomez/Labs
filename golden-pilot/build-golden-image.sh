#!/usr/bin/env bash
# build-golden-image.sh
#
# Descarga la imagen oficial "GenericCloud" de AlmaLinux 9 (ya viene con
# cloud-init preinstalado y configurado, lista para NoCloud/ConfigDrive)
# y la deja como imagen "dorada" de solo lectura. NUNCA se arranca esta
# imagen directamente -- cada VM usa un overlay copy-on-write encima,
# asi que la dorada queda intacta y se reusa para los 50 labs.
#
# Correr UNA sola vez. Requiere: qemu-img, virt-install, genisoimage
# (o cloud-localds), libvirt corriendo.

set -o errexit
set -o pipefail

IMG_DIR="$HOME/vm-images"
GOLDEN_IMG="$IMG_DIR/golden-almalinux9.qcow2"
ALMA_URL="https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2"

mkdir -p "$IMG_DIR"

echo "==> Verificando herramientas necesarias..."
for tool in qemu-img virt-install genisoimage virsh; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "FALTA: $tool -- instalalo antes de continuar."
    echo "  sudo apt install qemu-utils virtinst genisoimage libvirt-clients"
    exit 1
  fi
done
echo "==> Todas las herramientas presentes."

if [ -f "$GOLDEN_IMG" ]; then
  echo "==> La imagen dorada ya existe en $GOLDEN_IMG, no se vuelve a descargar."
  echo "    (borrala a mano si queres forzar una descarga nueva)"
  exit 0
fi

echo "==> Descargando imagen oficial AlmaLinux 9 GenericCloud..."
curl -L -o "$GOLDEN_IMG" "$ALMA_URL"

echo "==> Imagen dorada lista en: $GOLDEN_IMG"
qemu-img info "$GOLDEN_IMG"

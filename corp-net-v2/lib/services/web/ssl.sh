#!/bin/bash
# lib/services/web/ssl.sh

generate_certs() {
    local cert_dir="$BASE_DIR/lib/services/web/certs"
    mkdir -p "$cert_dir"

    # Solo generamos si no existen para no sobrescribir
    if [ ! -f "$cert_dir/server.key" ]; then
        echo "🔐 Generando certificados SSL auto-firmados..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$cert_dir/server.key" \
            -out "$cert_dir/server.crt" \
            -subj "/C=AR/ST=BA/L=City/O=CorpNet/CN=10.0.1.10"
        echo "✅ Certificados listos."
    fi
}
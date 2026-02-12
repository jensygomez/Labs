#!/bin/bash
# network-engine/phases/10-dns-resolver.sh

run_phase() {
  echo "[FASE 10] Configurando Resolvers Dinámicamente"

  # IP de nuestro servidor DNS centralizado
  # Podrías extraerla de addressing.conf, pero por ahora usamos la definida
  DNS_SERVER_IP="10.255.255.26"
  
  # Obtener todos los namespaces actuales
  local all_ns=$(ip netns list | cut -d' ' -f1)

  for ns in $all_ns; do
    # Excluimos el propio servidor DNS para evitar recursión infinita
    if [[ "$ns" == "$NS_SVC_DNS" ]]; then
      continue
    fi

    echo "🌐 Configurando DNS en namespace: $ns"
    
    # Asegurar que el directorio de configuración existe (por si acaso)
    mkdir -p "/etc/netns/$ns"
    
    # Escribir la configuración de resolución
    # 'options timeout:1' es útil en labs para que falle rápido si hay error
    cat <<EOF > "/etc/netns/$ns/resolv.conf"
nameserver $DNS_SERVER_IP
options timeout:1 attempts:1
EOF
  done

  echo "🎯 Todos los namespaces configurados para usar $DNS_SERVER_IP"
}
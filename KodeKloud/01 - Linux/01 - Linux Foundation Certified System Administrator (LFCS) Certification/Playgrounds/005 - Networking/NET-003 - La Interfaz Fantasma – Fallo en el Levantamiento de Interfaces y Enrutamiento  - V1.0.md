---
Curso: Prep Course - LFCS Certification
Modulo: Networking
Playground: NET-003-v1
Titulo: La Interfaz Fantasma – Fallo en el Levantamiento de Interfaces y Enrutamiento - V1.0
Fecha de Inicio: 2026-06-13
Dificultad: 7/10
Level Escalation: L2/L3
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Sysadmin Kubernetes (La red subyacente del nodo es crítica para el CNI)
Temas: |-
  - Network Interface Configuration (Netplan / systemd-networkd)
  - IPv4/IPv6 Networking and Subnetting
  - Routing Tables and Static Routes (ip route)
  - Network Service Management (apply/reload without reboot)
Competencias: |-
  - Diagnosticar fallos de conectividad a nivel de capa 2/3 (interfaces caídas, IPs mal configuradas o sin levantar).
  - Corregir archivos de configuración de red declarativos (YAML en Netplan o .network en systemd-networkd) y aplicarlos en caliente.
  - Manipular la tabla de enrutamiento del kernel añadiendo rutas estáticas para alcanzar subredes remotas (ej. redes de pods o almacenamiento).
  - Verificar el estado de la red utilizando herramientas modernas (ip addr, ip route, networkctl) en lugar de las obsoletas (ifconfig, route).
Script: |-
  cat << 'EOF' > /tmp/setup-net003.sh

  #!/bin/bash
  set -e

  # ── Parámetros del Clúster ──────────────────────────────────────────────────
  USER_NET="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

  # ─────────────────────────────────────────────────────────────────────────────
  # 1. INSTALAR SSHPASS LOCALMENTE (en node01, donde se ejecuta el script)
  # ─────────────────────────────────────────────────────────────────────────────
  echo -e "\e[1;33m⏳ Instalando sshpass en el nodo local (node01)...\e[0m"
  if ! command -v sshpass &>/dev/null; then
      if command -v apt-get &>/dev/null; then
          sudo apt-get update -qq && sudo apt-get install -y sshpass -qq
      elif command -v yum &>/dev/null; then
          sudo yum install -y sshpass -qq
      else
          echo -e "\e[1;31m✗ No se pudo instalar sshpass: no se encontró apt-get ni yum\e[0m"
          exit 1
      fi
  fi
  echo -e "\e[1;32m✔ sshpass instalado localmente.\e[0m"

  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  # ─────────────────────────────────────────────────────────────────────────────
  # 2. INSTALAR SSHPASS EN LOS NODOS REMOTOS
  # ─────────────────────────────────────────────────────────────────────────────
  for NODE in node01 node02 node03; do
      echo -e "\e[1;33m⏳ Instalando sshpass en $NODE...\e[0m"
      $SSH ${USER_NET}@${NODE} "
          if ! command -v sshpass &>/dev/null; then
              if command -v apt-get &>/dev/null; then
                  echo $PASS | sudo -S apt-get update -qq && echo $PASS | sudo -S apt-get install -y sshpass -qq
              elif command -v yum &>/dev/null; then
                  echo $PASS | sudo -S yum install -y sshpass -qq
              fi
          fi
      " < /dev/null
      echo -e "\e[1;32m✔ sshpass instalado en $NODE.\e[0m"
  done

  # ─────────────────────────────────────────────────────────────────────────────
  # 3. INYECTAR ESCENARIO EN node02 (Interfaz Fantasma y Ruta Faltante)
  # ─────────────────────────────────────────────────────────────────────────────
  echo -e "\e[1;33m⏳ Inyectando escenario de red rota en node02...\e[0m"
  # NOTA CRÍTICA: Usamos 'INNEREOF' con comillas simples para evitar que el shell remoto
  # expanda las variables antes de pasarlas a sudo. Todo se ejecuta en el bash de sudo.
  $SSH ${USER_NET}@${NODE_TARGET} "
    echo $PASS | sudo --stdin bash << 'INNEREOF'
      # 1. Crear interfaz dummy para simular la secundaria (persistente en esta sesión)
      ip link add dummy0 type dummy 2>/dev/null || true
      ip link set dummy0 up

      # 2. Inyectar configuración de red declarativa rota
      if command -v netplan &>/dev/null; then
        # ENTORNO UBUNTU/DEBIAN (Netplan)
        # Error intencional: Falta los dos puntos (:) después de 'addresses'
        # y no se incluye la directiva de rutas (routes)
        cat > /etc/netplan/60-secondary.yaml << 'NETPLAN'
  network:
    version: 2
    ethernets:
      dummy0:
        dhcp4: no
        addresses
          - 10.99.99.1/24
  NETPLAN
        netplan apply 2>/dev/null || true
      else
        # ENTORNO RHEL/CENTOS (systemd-networkd)
        mkdir -p /etc/systemd/network
        # Error intencional: Nombre de sección typo ([Networkx]) y falta [Route]
        cat > /etc/systemd/network/20-dummy0.network << 'NETWORK'
  [Match]
  Name=dummy0

  [Networkx]
  Address=10.99.99.1/24
  NETWORK
        systemctl restart systemd-networkd 2>/dev/null || true
      fi
      
      echo '[NET-003] Escenario de interfaz y enrutamiento inyectado en node02.'
      exit 0
  INNEREOF
  " < /dev/null
  echo -e "\e[1;32m✔ node02: Interfaz secundaria caída y config declarativa rota.\e[0m"

  # ─────────────────────────────────────────────────────────────────────────────
  # 4. PREPARAR BÓVEDA EN node03
  # ─────────────────────────────────────────────────────────────────────────────
  echo -e "\e[1;33m⏳ Preparando bóveda de evidencia en node03...\e[0m"
  $SSH ${USER_NET}@${NODE_VAULT} "
    echo $PASS | sudo --stdin bash << 'INNEREOF'
      rm -rf /opt/ops-compliance/net-003/
      mkdir -p /opt/ops-compliance/net-003/
      chown -R ${USER_NET}:${USER_NET} /opt/ops-compliance/net-003/
      chmod 750 /opt/ops-compliance/net-003/
      echo '[NET-003] Bóveda de evidencia en node03 preparada.'
      exit 0
  INNEREOF
  " < /dev/null
  echo -e "\e[1;32m✔ node03: Bóveda preparada.\e[0m"

  # ─────────────────────────────────────────────────────────────────────────────
  # 5. MOSTRAR EL TICKET (Nivel Senior / L2-L3)
  # ─────────────────────────────────────────────────────────────────────────────
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  TICKET INC-3003  │  Severidad: ALTA  │  Ambiente: CLÚSTER DISTRIBUIDO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  NET-003-MN — La Interfaz Fantasma: Enrutamiento y Capa 2\e[0m"
  echo -e "\e[1;36m  Módulo: Networking  │  Dificultad: 7/10  │  Nivel: L2/L3\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1mArquitectura del Escenario:\e[0m"
  echo -e "  \e[1;34m[node01]\e[0m → Estación del Administrador     (TU POSICIÓN ACTUAL)"
  echo -e "  \e[1;32m[node02]\e[0m → Servidor de Aplicaciones       (AFECTADO: INTERFAZ Y RUTAS)"
  echo -e "  \e[1;31m[node03]\e[0m → Servidor Backend / Bóveda      (DESTINO DE EVIDENCIA)"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  Tras una actualización de kernel y un reinicio del servicio de red en node02,"
  echo -e "  la interfaz secundaria (simulada como 'dummy0') no ha levantado. Esto ha"
  echo -e "  dejado aislado al nodo de la red interna del clúster. Además, el equipo de"
  echo -e "  Kubernetes reporta que los pods no pueden comunicarse con los servicios en"
  echo -e "  node03 porque falta la ruta estática hacia la subred de pods (10.244.0.0/16)."
  echo -e ""
  echo -e "  Al revisar los archivos de configuración declarativa de red en node02, se"
  echo -e "  sospecha que la migración reciente dejó un error de sintaxis en el archivo"
  echo -e "  de configuración y que la directiva de enrutamiento fue omitida por completo."
  echo -e ""
  echo -e " \e[1;33mRestricciones Operativas:\e[0m"
  echo -e "  \e[1;31m⚠\e[0m  No está permitido reiniciar el sistema operativo (reboot)."
  echo -e "     Los cambios deben aplicarse en caliente recargando el servicio de red."
  echo -e "  \e[1;31m⚠\e[0m  La configuración debe ser persistente en los archivos del sistema"
  echo -e "     (Netplan o systemd-networkd). No se aceptan soluciones efímeras solo con 'ip'."
  echo -e "  \e[1;31m⚠\e[0m  CERO archivos intermedios en node01. Todo debe fluir vía pipeline SSH."
  echo -e ""
  echo -e " \e[1;33mProcedimiento Requerido:\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1. Diagnóstico de Capa 2/3:\e[0m"
  echo -e "     Identifica la interfaz caída y localiza el archivo de configuración"
  echo -e "     declarativa que está fallando al cargarse por el servicio de red."
  echo -e ""
  echo -e "  \e[1;31m2. Ingeniería de Configuración Declarativa:\e[0m"
  echo -e "     Corrige el error de sintaxis en el archivo de configuración."
  echo -e "     Asegura que la interfaz levante con IP estática (10.99.99.1/24)."
  echo -e ""
  echo -e "  \e[1;31m3. Enrutamiento Estático Persistente:\e[0m"
  echo -e "     Integra la ruta estática hacia la subred 10.244.0.0/16 directamente"
  echo -e "     en el archivo de configuración de red (o mediante el mecanismo de"
  echo -e "     persistencia de rutas nativo de tu distribución)."
  echo -e ""
  echo -e "  \e[1;31m4. Aplicación en Caliente y Validación:\e[0m"
  echo -e "     Recarga el servicio de red para aplicar los cambios sin reiniciar."
  echo -e "     Verifica que la interfaz tenga la IP y que la tabla de enrutamiento"
  echo -e "     contenga la ruta hacia 10.244.0.0/16."
  echo -e ""
  echo -e "  \e[1;31m5. Pipeline de Evidencia a node03:\e[0m"
  echo -e "     Destino: /opt/ops-compliance/net-003/network_evidence.txt"
  echo -e "     La evidencia debe incluir la salida de 'ip addr show dummy0' y"
  echo -e "     'ip route show 10.244.0.0/16', enviada directamente desde node02."
  echo -e ""
  echo -e " \e[1;33mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Interfaz dummy0 UP con IP 10.99.99.1/24 asignada correctamente   --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Archivo de configuración declarativa sin errores de sintaxis      --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Ruta estática a 10.244.0.0/16 presente y persistente              --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Evidencia (network_evidence.txt) presente en la bóveda node03     --> \e[1;35m25%\e[0m"
  echo -e "  [ ] CERO archivos de resultados almacenados en node01  \e[1;31m(DESCALIFICA)\e[0m"
  echo -e ""
  echo -e " \e[1;36m================================================================================\e[0m"
  EOF

  bash /tmp/setup-net003.sh && rm -f /tmp/setup-net003.sh
tags:
  - Laboratorios-del-LFCS
  - Networking
  - Interfaces
  - Routing
  - Netplan
Escenario: |-
  -  Situación: Tras una actualización de kernel y un reinicio simulado en node02, la interfaz de red secundaria (ej. enp0s8, usada para el tráfico interno del clúster hacia node03) no levanta. Al revisar, se detecta que el archivo de configuración de red (Netplan o systemd-networkd) tiene un error de sintaxis YAML o una directiva incorrecta (por ejemplo, indentación rota o configuración DHCP cuando debería ser estática). Además, falta una ruta estática crítica para alcanzar la subred de los pods (10.244.0.0/16) o de almacenamiento en node03.
  - Tu misión:
    1. Identificar la interfaz caída y diagnosticar el error en el archivo de configuración de red mediante los logs del servicio de red.
    2. Corregir la sintaxis del archivo de configuración (asegurando IP estática, máscara de red correcta y gateway si aplica).
    3. Configurar la ruta estática faltante (ya sea de forma persistente en el archivo de configuración o temporalmente con ip route) para alcanzar la subred remota.
    4. Aplicar los cambios en caliente (sin reiniciar el servidor completo) y validar que la interfaz esté UP, tenga la IP correcta y la tabla de enrutamiento muestre la ruta estática.
---

[[Laboratorios del LFCS]]

---

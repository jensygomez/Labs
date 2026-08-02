---
Titulo: inc-001-boot-fstab-mount-failure.yml
Severidad: MEDIA
Ambiente: Produccion
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-07-31
Script Vagrant: |-
  # -*- mode: ruby -*-

  # vi: set ft=ruby :
  #
  # INC-001: The Ghost Reboot (NFS mount failure)
  # Topologia: node01/02/03 = flota de app | node04 = storage (NFS real)
  #
  # NO ABRAS este archivo linea por linea antes de terminar el triage si
  # queres practicar diagnostico en frio -- el nodo afectado y la causa
  # raiz estan mas abajo, marcados. Empeza siempre por el ticket.

  IP = {
    "node01" => "192.168.122.11",
    "node02" => "192.168.122.12",
    "node03" => "192.168.122.13",
    "node04" => "192.168.122.14",
  }
  STORAGE_IP = IP["node04"]
  STORAGE_EXPORT = "/srv/nfs/appdata"

  Vagrant.configure("2") do |config|

    # ============================================================
    # PROVISIONING GLOBAL -- igual en las 4 VMs
    # ============================================================
    config.vm.provision "shell", privileged: true, inline: <<-SHELL
      echo "Instalando herramientas base: lsof, vim, bash-completion..."
      if [ -f /etc/redhat-release ]; then
        dnf install -y lsof vim bash-completion nfs-utils
      else
        apt-get update -y
        apt-get install -y lsof vim bash-completion nfs-common
      fi
    SHELL

    config.vm.provision "shell", privileged: false, inline: <<-SHELL
      cat > ~/.vimrc <<-'VIMRC'
  set number
  syntax on
  set expandtab
  set tabstop=2
  set shiftwidth=2
  VIMRC
    SHELL

    # ============================================================
    # NODE04 -- storage real, exporta /srv/nfs/appdata via NFS
    # ============================================================
    config.vm.define "node04" do |n|
      n.vm.box = "almalinux/9"
      n.vm.hostname = "node04"
      n.vm.network "private_network",
        ip: IP["node04"], libvirt__network_name: "mgmt-net", libvirt__dhcp_enabled: false
      n.vm.provider "libvirt" do |lv|
        lv.memory = 1024
        lv.cpus = 1
        lv.driver = "kvm"
      end

      n.vm.provision "shell", privileged: true, inline: <<-SHELL
        echo "==> node04: configurando export NFS..."
        dnf install -y nfs-utils
        mkdir -p #{STORAGE_EXPORT}
        cat > #{STORAGE_EXPORT}/status <<-'STATUS'
  APP_VERSION=2.4.1
  LAST_SUCCESSFUL_DEPLOY=2024-01-15T14:30:00Z
  DB_CONNECTION_POOL=active
  CACHE_SIZE=512MB
  STATUS
        chown -R nobody:nobody #{STORAGE_EXPORT}
        chmod -R 777 #{STORAGE_EXPORT}
        echo "#{STORAGE_EXPORT} 192.168.122.0/24(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports
        systemctl enable --now rpcbind
        exportfs -ra
        systemctl enable --now nfs-server
        if systemctl is-active --quiet firewalld; then
          firewall-cmd --permanent --add-service=nfs --add-service=rpc-bind --add-service=mountd
          firewall-cmd --reload
        fi
        echo "==> node04 listo. Export:"
        exportfs -v
      SHELL
    end

    # ============================================================
    # FLOTA: node01, node02, node03 -- MISMO baseline en los 3
    # ============================================================
    ["node01", "node02", "node03"].each do |node|
      config.vm.define node do |n|
        n.vm.box = "almalinux/9"
        n.vm.hostname = node
        n.vm.network "private_network",
          ip: IP[node], libvirt__network_name: "mgmt-net", libvirt__dhcp_enabled: false
        n.vm.provider "libvirt" do |lv|
          lv.memory = 1024
          lv.cpus = 1
          lv.driver = "kvm"
        end

        # --- Baseline identico en los 3: monta NFS, arranca app-backend
        #     y el legacy-daemon (falso negativo). Corre SIEMPRE. ---
        n.vm.provision "shell", privileged: true, inline: <<-SHELL
          echo "==> #{node}: esperando a que node04 exporte NFS..."
          RETRY=0
          until showmount -e #{STORAGE_IP} 2>/dev/null | grep -q "#{STORAGE_EXPORT}"; do
            RETRY=$((RETRY + 1))
            if [ "$RETRY" -ge 30 ]; then
              echo "FATAL: node04 no respondio a tiempo" >&2
              exit 1
            fi
            sleep 5
          done

          mkdir -p /data
          echo "#{STORAGE_IP}:#{STORAGE_EXPORT} /data nfs defaults,_netdev,x-systemd.automount,x-systemd.mount-timeout=15 0 0" >> /etc/fstab
          mount -a

          cat > /etc/systemd/system/app-backend.service <<-'UNIT'
  [Unit]
  Description=Critical App Backend
  RequiresMountsFor=/data
  After=remote-fs.target network-online.target
  Wants=network-online.target

  [Service]
  Type=simple
  ExecStart=/bin/bash -c 'if [ -f "/data/status" ]; then echo "[$(date)] App started successfully" >> /data/status; sleep infinity; else echo "FATAL: /data/status not found" >&2; exit 1; fi'
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  UNIT

          mkdir -p /opt/legacy
          cat > /opt/legacy/start.sh <<-'LEGACY'
  #!/bin/bash
  echo "legacy-daemon: simulando fallo conocido (OPS-891)..."
  exit 1
  LEGACY
          chmod +x /opt/legacy/start.sh

          cat > /etc/systemd/system/legacy-daemon.service <<-'UNIT'
  [Unit]
  Description=Legacy Monitoring Daemon (known issue OPS-891)

  [Service]
  Type=simple
  ExecStart=/opt/legacy/start.sh
  Restart=always
  RestartSec=10

  [Install]
  WantedBy=multi-user.target
  UNIT

          systemctl daemon-reload
          systemctl enable --now legacy-daemon.service || true
          systemctl enable --now app-backend.service || true
          echo "==> #{node}: baseline completo."
        SHELL

        # --- El ticket vive en cada nodo de la flota, como en produccion
        #     real (no sabes por cual vas a entrar primero) ---
        n.vm.provision "shell", privileged: false, inline: <<-SHELL
          cat > ~/TICKET_INC-001.txt <<-'TICKET'
  ======================================================================
  OPS-1042 - INCIDENT - P1
  ======================================================================
  REPORTADO POR: Zabbix Monitoring        HORA: 03:14 AM
  RESUMEN: app-backend DOWN en fleet tras mantenimiento nocturno
  ======================================================================

  DESCRIPCION:
  Alerta automatica: el servicio app-backend dejo de responder en uno
  de los nodos de la flota de aplicacion (node01/02/03 -- el dashboard
  no especifica cual, el ping ICMP a los 3 nodos es exitoso). El
  mantenimiento programado de anoche incluyo un reinicio de kernel en
  toda la flota. El balanceador esta redirigiendo trafico a los nodos
  sanos, pero el cliente reporta lentitud intermitente porque la flota
  esta operando con capacidad reducida.

  NOTAS DEL TURNO ANTERIOR (L1 nocturno):
  "Reboot post-mantenimiento OK en los 3 nodos, todos responden ping y
  SSH. Vi una alarma de 'legacy-daemon' reiniciandose en loop en uno de
  los nodos, lo reinicie manualmente con systemctl restart un par de
  veces pero sigue cayendo -- parece el bug conocido que ya reportamos
  en OPS-891, no deberia ser el causante de la caida de app-backend.
  Dejo el ticket abierto para el proximo turno, no tuve tiempo de
  revisar mas a fondo."

  IMPACTO AL CLIENTE: Latencia intermitente y errores 502 esporadicos
  en checkout.

  CRITERIO DE RESOLUCION:
  1. Identificar y descartar la falsa alerta (legacy-daemon / OPS-891).
  2. Identificar la causa real que impide arrancar app-backend.
  3. Restaurar el mount de /data de forma persistente (sobrevive reboot).
  4. app-backend activo en los 3 nodos de la flota.
  5. Automatizar el fix en un playbook idempotente (site/playbooks/).
  ======================================================================
  TICKET
          echo "Ticket disponible en ~/TICKET_INC-001.txt"
        SHELL
      end
    end

    # ============================================================
    # CAUSA RAIZ -- SOLO en el nodo elegido. NO LEER si queres
    # practicar diagnostico en frio.
    #
    # Nodo afectado: node02
    # Fallo: fstab reemplazado con IP incorrecta y SIN _netdev, asi que
    # systemd intenta montar antes de que la red este lista, apuntando
    # ademas a un servidor NFS que no existe.
    # ============================================================
    config.vm.define "node02" do |n|
      n.vm.provision "shell", privileged: true, inline: <<-SHELL
        echo "[FAULT] Rompiendo mount NFS en node02..."
        umount /data 2>/dev/null || true
        sed -i '/\\/data nfs/d' /etc/fstab
        echo "192.168.122.99:#{STORAGE_EXPORT} /data nfs defaults 0 0" >> /etc/fstab
        systemctl daemon-reload
        mount -a || true
        systemctl restart app-backend.service || true

        # Script de re-inyeccion, para practicar el fix mas de una vez
        # sin destruir la VM (mismo patron que ya usabas en inc-003)
        cat > /home/vagrant/break-mount.sh <<-'BREAK'
  #!/bin/bash
  set -e
  echo "Re-inyectando INC-001 en $(hostname)..."
  umount /data 2>/dev/null || true
  sed -i '/\\/data nfs/d' /etc/fstab
  echo "192.168.122.99:/srv/nfs/appdata /data nfs defaults 0 0" >> /etc/fstab
  systemctl daemon-reload
  mount -a || true
  systemctl restart app-backend.service || true
  echo "Incidente re-inyectado. Corre tu playbook de fix y despues validate con el healthcheck."
  BREAK
        chmod +x /home/vagrant/break-mount.sh
        chown vagrant:vagrant /home/vagrant/break-mount.sh
        echo "[FAULT] Listo."
      SHELL
    end

  end
---
[[Laboratorios del LFCS]]

---


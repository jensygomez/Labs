---
Titulo: inc-002-storage-var-log-disk-full.yml
Severidad: MEDIA
Ambiente: Produccion
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-08-01
Script Vagrant: |-
  # -*- mode: ruby -*-

  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "almalinux/9"

    # Provisioning global: instala ansible-playbook, lsof y vim en todos los nodos
    config.vm.provision "shell", privileged: true, inline: <<-SHELL
      echo "Instalando herramientas base: ansible-core, lsof, vim..."
      dnf install -y epel-release
      dnf install -y ansible-core lsof vim
    SHELL

    # Tip de Pro: dejamos ~/.vimrc configurado para el usuario vagrant desde el arranque
    config.vm.provision "shell", privileged: false, inline: <<-SHELL
      echo "Configurando ~/.vimrc para el usuario vagrant..."
      cat > ~/.vimrc <<-'VIMRC'
  set number
  syntax on
  set expandtab
  set tabstop=2
  set shiftwidth=2
  VIMRC
    SHELL

    # Single node topology for INC-002
    config.vm.define "node01" do |node_config|
      node_config.vm.hostname = "node01"
      node_config.vm.network "private_network",
        ip: "192.168.122.11",
        libvirt__network_name: "mgmt-net",
        libvirt__dhcp_enabled: false
      node_config.vm.provider "libvirt" do |lv|
        lv.memory = 4096
        lv.cpus = 4
        lv.driver = "kvm"
        # Small dedicated disk so it's realistic to fill up
        lv.storage :file, :size => '512M', :type => 'qcow2'
      end
      node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
        echo "Setting up INC-002: The Silent Fill..."

        # 1. Format and mount the dedicated log disk
        mkfs.xfs -f /dev/vdb
        REAL_UUID=$(blkid -s UUID -o value /dev/vdb)
        mkdir -p /var/log/app-metrics
        mount /dev/vdb /var/log/app-metrics
        echo "UUID=$REAL_UUID /var/log/app-metrics xfs defaults 0 0" >> /etc/fstab

        # 2. FALSE NEGATIVE: a large, already-compressed, STATIC old debug log.
        #    It looks suspicious (largest single file) but deleting it only
        #    buys temporary space -- it never grows again.
        dd if=/dev/urandom of=/var/log/app-metrics/legacy-debug.log.1.gz bs=1M count=60 status=none

        # 3. ROOT CAUSE SETUP: the active application log, already large from
        #    months of unbounded growth (no logrotate policy was ever created
        #    for this app).
        dd if=/dev/zero of=/var/log/app-metrics/metrics.log bs=1M count=190 status=none

        chown -R vagrant:vagrant /var/log/app-metrics

        # 4. Create the app-metrics service. It periodically appends to
        #    metrics.log (simulating a real, still-growing log) and will
        #    fail to write once the disk is completely full.
        cat <<'EOF' > /usr/local/bin/app-metrics-writer.sh
  #!/bin/bash
  while true; do
    if ! echo "[$(date -Iseconds)] metric_sample cpu=$(shuf -i 1-100 -n1) mem=$(shuf -i 1-100 -n1)" >> /var/log/app-metrics/metrics.log; then
      echo "FATAL: could not write to metrics.log, disk full?" >&2
      exit 1
    fi
    sleep 5
  done
  EOF
        chmod +x /usr/local/bin/app-metrics-writer.sh

        cat <<EOF > /etc/systemd/system/app-metrics.service
  [Unit]
  Description=App Metrics Collector
  RequiresMountsFor=/var/log/app-metrics
  After=local-fs.target
  StartLimitIntervalSec=60
  StartLimitBurst=3

  [Service]
  Type=simple
  ExecStart=/usr/local/bin/app-metrics-writer.sh
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
        systemctl daemon-reload
        systemctl enable --now app-metrics.service

        # 5. Note: NO logrotate policy exists for app-metrics on purpose.
        #    This is the real root cause of the disk filling up over time.

        # 6. Generate the ticket
        cat <<'TICKET' > /home/vagrant/TICKET_INCIDENT-02.txt
  ======================================================================
  INCIDENT TICKET #02 - HIGH PRIORITY
  ======================================================================
  TITLE: /var/log/app-metrics partition almost full, app-metrics service
         intermittently failing
  SEVERITY: SEV-2
  REPORTED BY: Monitoring System (automated alert)
  ======================================================================

  DESCRIPTION:
  "Disk usage alert fired for the /var/log/app-metrics partition on
  node01 -- currently above 85% used. The app-metrics service has
  restarted several times in the last hour with write errors in its
  logs.

  While investigating, we noticed a very large file called
  'legacy-debug.log.1.gz' sitting in that same directory -- it looks
  like the obvious space hog. However, previous on-call engineers have
  mentioned that clearing space here has only provided temporary
  relief in the past; the partition fills up again within days.

  Please investigate and provide a PERMANENT fix, not just a one-time
  cleanup."

  EVALUATION CRITERIA:
  1. Identify and discard the false negative (the static compressed
     legacy log -- confirm whether it is actually still growing).
  2. Identify the real root cause of the recurring disk fill.
  3. Free enough space to bring the partition back to a healthy level.
  4. Ensure app-metrics.service is running and stable.
  5. Prevent this from recurring (this becomes the Phase 2 Ansible task).

  ESTIMATED TIME: 60 - 75 minutes.
  ======================================================================
  TICKET

        # 7. Generate the validator (Golden Rule: only checks real root
        #    cause resolution, never forces deletion of the false negative)
        cat <<'VALIDATOR' > /home/vagrant/validate.sh
  #!/bin/bash
  CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; MAGENTA='\033[0;35m'; RESET='\033[0m'
  TOTAL=0; PASS_COUNT=0; FAIL_COUNT=0

  print_res() {
    local n=$1; local name=$2; local pts=$3; local pass=$4; local desc=$5
    echo -e "\n${CYAN}CHECK $n: $name ($pts pts)${RESET}"
    echo -e "${YELLOW}   $desc${RESET}"
    if [ "$pass" -eq 1 ]; then
      echo -e "   ${GREEN}PASS +$pts pts${RESET}"
      TOTAL=$((TOTAL + pts)); PASS_COUNT=$((PASS_COUNT + 1))
    else
      echo -e "   ${RED}FAIL +0 pts${RESET}"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  }

  echo -e "${MAGENTA}Validating INC-002 Resolution...${RESET}"

  # Check 1: disk usage below 80%
  USAGE=$(df --output=pcent /var/log/app-metrics | tail -1 | tr -dc '0-9')
  if [ "$USAGE" -lt 80 ]; then ok=1; else ok=0; fi
  print_res 1 "Disk Usage Healthy" 3 $ok "/var/log/app-metrics usage is below 80% (currently ${USAGE}%)"

  # Check 2: app-metrics.service active
  STATUS=$(systemctl is-active app-metrics.service)
  if [ "$STATUS" == "active" ]; then ok=1; else ok=0; fi
  print_res 2 "Service Active" 3 $ok "app-metrics.service is active (status: $STATUS)"

  # Check 3: metrics.log itself is not unreasonably large (proves it was
  # rotated/truncated, not just that the red herring was deleted)
  LOG_SIZE_MB=$(du -m /var/log/app-metrics/metrics.log 2>/dev/null | cut -f1)
  if [ -n "$LOG_SIZE_MB" ] && [ "$LOG_SIZE_MB" -lt 50 ]; then ok=1; else ok=0; fi
  print_res 3 "Active Log Under Control" 3 $ok "metrics.log size is under 50MB (currently ${LOG_SIZE_MB:-unknown}MB)"

  # Check 4: a logrotate policy now exists for app-metrics (permanent fix)
  if [ -f /etc/logrotate.d/app-metrics ] && grep -q "metrics.log" /etc/logrotate.d/app-metrics; then ok=1; else ok=0; fi
  print_res 4 "Logrotate Policy Present" 4 $ok "/etc/logrotate.d/app-metrics exists and references metrics.log"

  echo -e "\n${CYAN}SUMMARY${RESET}"
  echo -e "Passed: ${GREEN}$PASS_COUNT${RESET} | Failed: ${RED}$FAIL_COUNT${RESET} | Total Score: ${YELLOW}$TOTAL / 13${RESET}"
  VALIDATOR

        # 8. Generate the break script (for Phase 2 idempotency testing)
        cat <<'BREAKSCRIPT' > /home/vagrant/break-diskfull.sh
  #!/bin/bash
  # Re-injects INC-002 without destroying the VM.
  set -e
  echo "Re-injecting INC-002 (oversized metrics.log, no logrotate policy)..."

  systemctl stop app-metrics.service 2>/dev/null || true
  rm -f /etc/logrotate.d/app-metrics
  dd if=/dev/zero of=/var/log/app-metrics/metrics.log bs=1M count=190 status=none
  chown vagrant:vagrant /var/log/app-metrics/metrics.log
  systemctl start app-metrics.service

  echo "Incident re-injected. Run your Ansible playbook now, then validate.sh"
  BREAKSCRIPT

        chmod +x /home/vagrant/validate.sh /home/vagrant/break-diskfull.sh
        chown vagrant:vagrant /home/vagrant/validate.sh /home/vagrant/break-diskfull.sh /home/vagrant/TICKET_INCIDENT-02.txt

        echo "INC-002 deployed successfully."
        echo "Read the ticket: cat /home/vagrant/TICKET_INCIDENT-02.txt"
        echo "When done, validate: bash /home/vagrant/validate.sh"
        echo "To re-test Ansible remediation: sudo bash /home/vagrant/break-diskfull.sh"
      SHELL
    end
  end
---
[[Laboratorios del LFCS]]

---


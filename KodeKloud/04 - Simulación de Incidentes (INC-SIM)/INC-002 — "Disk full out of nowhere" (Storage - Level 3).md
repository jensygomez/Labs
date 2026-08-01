---
Titulo: INC-001 — "El servidor no volvió del reboot" (Boot - Nivel 3)
Severidad: MEDIA
Ambiente: Produccion
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-07-31
Script Vagrant: |-
  # -*- mode: ruby -*-
  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "almalinux/9"
    
    # Single node topology for Incident #02
    config.vm.define "node01" do |node_config|
      node_config.vm.hostname = "node01"
      
      node_config.vm.network "private_network", 
        ip: "192.168.122.12", 
        libvirt__network_name: "mgmt-net",
        libvirt__dhcp_enabled: false

      node_config.vm.provider "libvirt" do |lv|
        lv.memory = 4096
        lv.cpus = 4
        lv.driver = "kvm"
        # Extra disk for the storage incident (2GB to safely hold /var contents + fake logs)
        lv.storage :file, :size => '2G', :type => 'qcow2'
      end

        # ----- PROVISIONING: BREAKING THE SYSTEM -----
        node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
          echo "🔧 Setting up Incident #02: Disk full out of nowhere..."
          
          # 1. Stop services that write to /var to safely migrate it
          systemctl stop rsyslog systemd-journald
          
          # 2. Format the extra disk (/dev/vdb) and mount temporarily
          mkfs.xfs -f /dev/vdb
          mkdir -p /mnt
          mount /dev/vdb /mnt
          
          # 3. Copy existing /var contents to the new disk
          cp -a /var/* /mnt/
          
          # 4. Unmount and mount permanently to /var
          umount /mnt
          mount /dev/vdb /var
          
          # 5. Add to fstab for persistence
          REAL_UUID=$(blkid -s UUID -o value /dev/vdb)
          echo "UUID=$REAL_UUID /var xfs defaults 0 0" >> /etc/fstab
          
          # 6. Restart services
          systemctl start systemd-journald rsyslog
          
          # 7. Create the FALSE NEGATIVE: Old journal files taking up space
          MACHINE_ID=$(cat /etc/machine-id)
          mkdir -p /var/log/journal/$MACHINE_ID
          # Create a 500MB fake old journal file
          dd if=/dev/zero of=/var/log/journal/$MACHINE_ID/system@0005a-0000000-0000000-0000000.journal bs=1M count=500 status=none
          
          # 8. Create the REAL ROOT CAUSE: Giant application log
          mkdir -p /var/log/myapp
          # Create a 1200MB log file that fills the 2GB /var partition
          dd if=/dev/zero of=/var/log/myapp/debug.log bs=1M count=1200 status=none
          
          # 9. Create the App Worker Service (Fails because /var is 100% full)
          cat <<EOF > /etc/systemd/system/myapp-worker.service
  [Unit]
  Description=MyApp Background Worker
  After=network.target

  [Service]
  Type=simple
  ExecStart=/bin/bash -c 'while true; do echo "[\$(date)] Processing background task..." >> /var/log/myapp/debug.log; sleep 5; done'
  Restart=on-failure
  RestartSec=5

  [Install]
  WantedBy=multi-user.target
  EOF
          systemctl daemon-reload
          systemctl enable myapp-worker.service
          
          # Start it so it immediately fails and enters a restart loop
          systemctl start myapp-worker.service

          # 10. Generate the Ticket and Validator
          cat <<'TICKET' > /home/vagrant/TICKET_INCIDENT-02.txt
  ======================================================================
  INCIDENT TICKET #02 - CRITICAL
  ======================================================================
  TITLE: Disk full out of nowhere - App worker down
  SEVERITY: SEV-2
  REPORTED BY: NOC Team
  ======================================================================

  DESCRIPTION:
  "Hi team, we are receiving critical alerts that the /var filesystem 
  on node01 is at 100% capacity. Because of this, the 'myapp-worker' 
  background service is constantly crashing and failing to process tasks.

  We noticed that systemd-journal is taking up a massive amount of space 
  (over 500MB of old archived journals). We tried running 
  'journalctl --vacuum-time=1d' but it didn't free up enough space and 
  the worker is still down. Please investigate the root cause of the 
  disk exhaustion and restore the worker service ASAP."

  EVALUATION CRITERIA:
  1. Identify and discard the false negative (old systemd journals).
  2. Identify the real root cause consuming the disk space in /var.
  3. Free up space in the /var filesystem (usage must drop below 90%).
  4. Ensure 'myapp-worker' is running and healthy.

  ESTIMATED TIME: 60 - 75 minutes.
  ======================================================================
  TICKET

          cat <<'VALIDATOR' > /home/vagrant/validate.sh
  #!/bin/bash
  # Local validator for Incident #02

  CYAN='\\033[0;36m'; GREEN='\\033[0;32m'; RED='\\033[0;31m'; YELLOW='\\033[0;33m'; RESET='\\033[0m'
  TOTAL=0; PASS_COUNT=0; FAIL_COUNT=0

  print_res() {
    local n=$1; local name=$2; local pts=$3; local pass=$4; local desc=$5; local out=$6
    echo -e "\\n${CYAN}┌─ CHECK $n: $name ($pts pts) ─${RESET}"
    echo -e "${YELLOW}   $desc${RESET}"
    if [ "$pass" -eq 1 ]; then
      echo -e "   ${GREEN}✅ +$pts pts${RESET}"
      TOTAL=$((TOTAL + pts)); PASS_COUNT=$((PASS_COUNT + 1))
    else
      echo -e "   ${RED}❌ +0 pts${RESET}"
      echo -e "   ${YELLOW}   Output obtained:${RESET}"
      echo "$out" | head -n 3 | sed 's/^/   /'
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  }

  echo -e "${CYAN}🔍 Validating Incident #02 Resolution...${RESET}"

  # Check 1: /var usage is below 90%
  out=$(df -h /var | tail -n 1 | awk '{print $5}' | sed 's/%//')
  if [ "$out" -lt 90 ] 2>/dev/null; then ok=1; else ok=0; fi
  print_res 1 "Filesystem Capacity" 3 $ok "/var filesystem usage is below 90%" "Current usage: ${out}%"

  # Check 2: The giant app log is removed or truncated
  out=$(stat -c %s /var/log/myapp/debug.log 2>/dev/null || echo "0")
  if [ "$out" -lt 10485760 ] 2>/dev/null; then ok=1; else ok=0; fi
  print_res 2 "Giant Log Cleared" 4 $ok "/var/log/myapp/debug.log is deleted or truncated (<10MB)" "File size: $out bytes"

  # Check 3: myapp-worker is running
  out=$(systemctl is-active myapp-worker.service)
  if [ "$out" == "active" ]; then ok=1; else ok=0; fi
  print_res 3 "App Worker Status" 4 $ok "myapp-worker.service is active" "$out"

  # Check 4: App is successfully writing to the log (proves it's working)
  sleep 6
  out=$(tail -n 1 /var/log/myapp/debug.log 2>/dev/null)
  if echo "$out" | grep -q "Processing background task"; then ok=1; else ok=0; fi
  print_res 4 "App Runtime Log" 3 $ok "Application is successfully writing new logs" "$out"

  echo -e "\\n${CYAN}└─ SUMMARY ─${RESET}"
  echo -e "Passed: ${GREEN}$PASS_COUNT${RESET} | Failed: ${RED}$FAIL_COUNT${RESET} | Total Score: ${YELLOW}$TOTAL / 14${RESET}"
  VALIDATOR
          chmod +x /home/vagrant/validate.sh
          chown vagrant:vagrant /home/vagrant/validate.sh /home/vagrant/TICKET_INCIDENT-02.txt

          echo "✅ Incident #02 deployed successfully."
          echo "🚀 vagrant ssh node01"
          echo "📝 Read the ticket: cat /home/vagrant/TICKET_INCIDENT-02.txt"
          echo "🔍 When done, validate: bash /home/vagrant/validate.sh"
        SHELL
    end
  end
---
[[Laboratorios del LFCS]]

---


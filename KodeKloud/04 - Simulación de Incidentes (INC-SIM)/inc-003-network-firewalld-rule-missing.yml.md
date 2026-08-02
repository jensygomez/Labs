---
Titulo: inc-003-network-firewalld-rule-missing.yml
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
      dnf install -y ansible-core lsof vim bash-completion
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

    # Single node topology for INC-003
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
      end
      
      node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
        echo "Setting up INC-003: The Missing Firewall Rule..."

        # 1. Install and configure Nginx to listen on port 8080
        dnf install -y nginx firewalld
        
        # Change default port from 80 to 8080
        sed -i 's/listen       80 default_server;/listen       8080 default_server;/' /etc/nginx/nginx.conf
        sed -i 's/listen       \\[::\\]:80 default_server;/listen       \\[::\\]:8080 default_server;/' /etc/nginx/nginx.conf

        systemctl enable --now nginx
        systemctl enable --now firewalld

        # 2. FALSE NEGATIVE INJECTION: 
        # Add a custom direct rule that drops traffic to port 9999. 
        # It looks suspicious and complex, but has absolutely nothing to do with port 8080.
        firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -p tcp --dport 9999 -j DROP
        firewall-cmd --reload

        # 3. ROOT CAUSE SETUP: 
        # Port 8080 is simply never opened in the firewalld configuration.
        # The default 'public' zone only allows ssh and dhcpv6-client.

        # 4. Generate the ticket
        cat <<'TICKET' > /home/vagrant/TICKET_INCIDENT-03.txt
  ======================================================================
  INCIDENT TICKET #03 - HIGH PRIORITY
  ======================================================================
  TITLE: External connectivity to new web application (port 8080) failing
  SEVERITY: SEV-2
  REPORTED BY: DevOps Team
  ======================================================================

  DESCRIPTION:
  "We just deployed the new internal web dashboard on node01. The 
  application is running and listening on port 8080. We can successfully 
  curl it locally from the server itself, but any connection from our 
  monitoring station and other internal subnets times out.

  The previous on-call engineer started looking into it and noticed some 
  custom DROP rules in the firewall configuration (visible via 
  'firewall-cmd --direct --get-all-rules'). They suspect these custom 
  rules might be interfering with the new application traffic, but they 
  couldn't figure out how to modify them without breaking other things.

  Please investigate the network path, verify the firewall state, and 
  restore external connectivity to port 8080."

  EVALUATION CRITERIA:
  1. Verify the application is actually listening on the correct interface/port.
  2. Investigate the firewall configuration and rule out any unrelated 
     custom rules that might be causing confusion.
  3. Identify the actual missing configuration preventing external access.
  4. Apply the correct permanent fix to allow traffic to port 8080.
  5. Ensure the fix survives a firewall reload or system reboot.

  ESTIMATED TIME: 60 - 75 minutes.
  ======================================================================
  TICKET

        # 5. Generate the validator (Golden Rule: only checks real root
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

  echo -e "${MAGENTA}Validating INC-003 Resolution...${RESET}"

  # Check 1: Nginx is active and listening on 8080
  STATUS=$(systemctl is-active nginx)
  LISTEN=$(ss -tulpn | grep -q ':8080' && echo "yes" || echo "no")
  if [ "$STATUS" == "active" ] && [ "$LISTEN" == "yes" ]; then ok=1; else ok=0; fi
  print_res 1 "App Running & Listening" 3 $ok "Nginx is active and listening on port 8080"

  # Check 2: Port 8080 is open in firewalld (runtime)
  if firewall-cmd --query-port=8080/tcp >/dev/null 2>&1; then ok=1; else ok=0; fi
  print_res 2 "Port Open (Runtime)" 3 $ok "Port 8080/tcp is allowed in firewalld runtime configuration"

  # Check 3: Port 8080 is open in firewalld (permanent)
  if firewall-cmd --permanent --query-port=8080/tcp >/dev/null 2>&1; then ok=1; else ok=0; fi
  print_res 3 "Port Open (Permanent)" 4 $ok "Port 8080/tcp is allowed in firewalld permanent configuration"

  # Check 4: The false negative (port 9999 rule) is still intact, proving 
  # we didn't just wipe the whole firewall config to fix the issue.
  if firewall-cmd --direct --get-all-rules | grep -q "9999"; then ok=1; else ok=0; fi
  print_res 4 "Unrelated Rules Intact" 2 $ok "The legacy direct rule for port 9999 was left untouched (Golden Rule)"

  echo -e "\n${CYAN}SUMMARY${RESET}"
  echo -e "Passed: ${GREEN}$PASS_COUNT${RESET} | Failed: ${RED}$FAIL_COUNT${RESET} | Total Score: ${YELLOW}$TOTAL / 12${RESET}"
  VALIDATOR

        # 6. Generate the break script (for Phase 2 idempotency testing)
        cat <<'BREAKSCRIPT' > /home/vagrant/break-firewalld.sh
  #!/bin/bash
  # Re-injects INC-003 without destroying the VM.
  set -e
  echo "Re-injecting INC-003 (removing port 8080 from firewalld)..."

  firewall-cmd --permanent --remove-port=8080/tcp 2>/dev/null || true
  firewall-cmd --reload

  echo "Incident re-injected. Run your Ansible playbook now, then validate.sh"
  BREAKSCRIPT

        chmod +x /home/vagrant/validate.sh /home/vagrant/break-firewalld.sh
        chown vagrant:vagrant /home/vagrant/validate.sh /home/vagrant/break-firewalld.sh /home/vagrant/TICKET_INCIDENT-03.txt

        echo "INC-003 deployed successfully."
        echo "Read the ticket: cat /home/vagrant/TICKET_INCIDENT-03.txt"
        echo "When done, validate: bash /home/vagrant/validate.sh"
        echo "To re-test Ansible remediation: sudo bash /home/vagrant/break-firewalld.sh"
      SHELL
    end
  end
---
[[Laboratorios del LFCS]]

---


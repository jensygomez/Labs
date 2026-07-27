---
Titulo: SIMULACRO LFCS 010 — "Advanced Operations and Recovery"
Severidad: MEDIA
Ambiente: Produccion
Modulo: LFCS Complete
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-07-27
Script Vagrant: |-
  # -- mode: ruby --
  # vi: set ft=ruby :
  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"

    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: [] },
      { name: "node03", ip: "192.168.122.13", extra_disks: [] }
    ]

    nodes.each do |node|
      config.vm.define node[:name] do |node_config|
        node_config.vm.hostname = node[:name]
        
        node_config.vm.network "private_network",
          ip: node[:ip],
          libvirt__network_name: "mgmt-net",
          libvirt__dhcp_enabled: false

        node_config.vm.provider "libvirt" do |lv|
          lv.memory = 1024
          lv.cpus = 1
          lv.driver = "kvm"
          node[:extra_disks].each do |size|
            lv.storage :file, :size => size, :type => 'qcow2'
          end
        end

        # ── GENERAL PROVISIONING (all nodes) ──
        node_config.vm.provision "shell", inline: <<-SHELL
          echo "🔧 Configuring #{node[:name]}..."
          for host in node01 node02 node03; do
            sed -i "/$host/d" /etc/hosts
          done
          cat << 'HOSTS' >> /etc/hosts
  192.168.122.11 node01
  192.168.122.12 node02
  192.168.122.13 node03
  HOSTS
          useradd -m -s /bin/bash bob 2>/dev/null || true
          echo 'bob:caleston123' | chpasswd
          echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
          chmod 0440 /etc/sudoers.d/bob
          
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq sshpass curl acl samba vsftpd at locales
        SHELL

        # ── NODE02: SERVER WITH 12 INCIDENTS ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🖥️ Configuring node02 with 12 incidents..."
            export DEBIAN_FRONTEND=noninteractive
            
            # ── TASK 1: htop not installed yet ──
            apt-get remove -y htop 2>/dev/null || true
            
            # ── TASK 2: user bob exists, no password aging set ──
            chage -M 99999 bob 2>/dev/null || true
            
            # ── TASK 3: no script yet ──
            rm -rf /opt/scripts 2>/dev/null || true
            
            # ── TASK 4: remove any sudoers for bob (except the NOPASSWD:ALL) ──
            # We'll keep the general NOPASSWD:ALL for vagrant operations
            # but the student must create a specific restricted entry
            
            # ── TASK 5: at command available ──
            systemctl enable atd 2>/dev/null
            systemctl start atd 2>/dev/null
            
            # ── TASK 6: create app log for logrotate ──
            mkdir -p /var/log
            echo "Application started" > /var/log/app.log
            echo "User logged in" >> /var/log/app.log
            echo "Error occurred" >> /var/log/app.log
            
            # ── TASK 7: DNS currently using default ──
            # resolv.conf will be managed by systemd-resolved
            
            # ── TASK 8: samba not configured ──
            systemctl stop smbd 2>/dev/null || true
            systemctl disable smbd 2>/dev/null || true
            rm -f /etc/samba/smb.conf 2>/dev/null || true
            
            # ── TASK 9: start a long-running process for renice ──
            su - bob -c "sleep 7200 &" 2>/dev/null
            sleep 2
            
            # ── TASK 10: alternatives for pager ──
            update-alternatives --install /usr/bin/pager pager /bin/less 50 2>/dev/null || true
            update-alternatives --install /usr/bin/pager pager /bin/more 30 2>/dev/null || true
            
            # ── TASK 11: locale currently en_US.UTF-8 ──
            locale-gen en_US.UTF-8 2>/dev/null
            update-locale LANG=en_US.UTF-8 2>/dev/null
            
            # ── TASK 12: no nproc limits set ──
            rm -f /etc/security/limits.d/99-nproc.conf 2>/dev/null || true
            
            echo "✅ node02 configured with 12 incidents"
          SHELL
        end

        # ── NODE03: VAULT ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparing vault..."
            mkdir -p /opt/ops-compliance/mock-exam-013
            chown -R bob:bob /opt/ops-compliance
            chmod -R 755 /opt/ops-compliance
            echo "✅ Vault ready at /opt/ops-compliance/mock-exam-013/"
          SHELL
        end

        # ── NODE01: TICKET + VERIFICATION + VALIDATOR (evidence‑based) ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generating Ticket, verification, validator, and evidence script on node01..."
            
            # ═══════════════════════════════════════════════════════
            # TICKET (English)
            # ═══════════════════════════════════════════════════════
            cat << 'TICKET' > /home/vagrant/TICKET_MOCK-013.txt
  ================================================================================
  TICKET MOCK-013   │  Severity: MEDIUM  │  Environment: PRODUCTION
  🔐 MOCK-013 — The Alternative Frontier (12 Tasks)
  Module: LFCS Complete  │  Difficulty: 3/10  │  Level: L2
  Control Station:    node01  (Administrator — bob)
  Server Node:        node02  (Ubuntu 22.04)
  Vault Destination:  node03  (/opt/ops-compliance/mock-exam-013/)
  Cluster Password:   caleston123

  This mock covers the same LFCS domains as Mock #9 but requires alternative 
  tools (htop, chage, at, logrotate, samba, renice, etc.). 
  Manage your time: ~8–10 minutes per task. If stuck, move on.
  ================================================================================
  TASK 1 — Essential Commands: Install and Verify Package (3 points)
  ================================================================================
  Install the `htop` package on node02.
  Verify it's installed by running `htop --version` and save the output to 
  /opt/htop-version.txt.
  CRITERIA:
  [ ] Package htop is installed (dpkg -l htop)                              --> 50%
  [ ] /opt/htop-version.txt exists and contains version info                 --> 50%
  TIME: 8 minutes
  ================================================================================
  TASK 2 — Security: Configure Password Aging (3 points)
  ================================================================================
  For user `bob`, configure password aging policies:
  - Maximum password age: 90 days
  - Minimum password age: 7 days
  - Warning period: 14 days
  Use the `chage` command.
  CRITERIA:
  [ ] Maximum age is 90 days (chage -l bob)                                 --> 35%
  [ ] Minimum age is 7 days                                                  --> 35%
  [ ] Warning period is 14 days                                              --> 30%
  TIME: 10 minutes
  ================================================================================
  TASK 3 — Scripts: Create Executable Script (3 points)
  ================================================================================
  Create a script `/opt/scripts/disk-check.sh` that:
  1. Outputs the current disk usage (use `df -h`)
  2. Logs the output to `/var/log/disk-check.log` with timestamp
  Make it executable and run it once.
  CRITERIA:
  [ ] Script exists at /opt/scripts/disk-check.sh                           --> 30%
  [ ] Script is executable (chmod +x)                                        --> 30%
  [ ] /var/log/disk-check.log exists and contains disk usage                --> 40%
  TIME: 12 minutes
  ================================================================================
  TASK 4 — Users/Sudo: Restricted Sudo Access (3 points)
  ================================================================================
  Create a sudoers entry that allows user `bob` to run ONLY `/usr/bin/journalctl` 
  without a password. Do NOT give full NOPASSWD:ALL (that already exists for 
  operational purposes).
  Hint: Create /etc/sudoers.d/bob-journal with the specific rule.
  CRITERIA:
  [ ] File /etc/sudoers.d/bob-journal exists                                --> 30%
  [ ] Contains rule for bob to run journalctl NOPASSWD                      --> 40%
  [ ] Syntax is valid (sudo -l -U bob shows the rule)                       --> 30%
  TIME: 10 minutes
  ================================================================================
  TASK 5 — Operations: Schedule Job with 'at' (3 points)
  ================================================================================
  Use the `at` command to schedule a job that runs in 5 minutes from now:
  The job should execute: echo "Scheduled task completed" >> /var/log/at-job.log
  CRITERIA:
  [ ] Job is scheduled (atq shows a job)                                    --> 40%
  [ ] Job command is correct (at -c <job_id> shows the echo command)        --> 60%
  TIME: 10 minutes
  ================================================================================
  TASK 6 — Logging: Configure Logrotate (3 points)
  ================================================================================
  Configure logrotate for `/var/log/app.log`:
  - Rotate daily
  - Keep 7 rotations
  - Compress old logs
  - Create file with permissions 640, owner root:adm
  Create the config in /etc/logrotate.d/app-log
  CRITERIA:
  [ ] Config file exists at /etc/logrotate.d/app-log                        --> 30%
  [ ] Contains daily rotation                                               --> 20%
  [ ] Contains rotate 7                                                      --> 20%
  [ ] Contains compress                                                      --> 15%
  [ ] Contains create directive with correct permissions                    --> 15%
  TIME: 12 minutes
  ================================================================================
  TASK 7 — Networking: Configure DNS Resolver (3 points)
  ================================================================================
  Configure the system to use Google DNS (8.8.8.8) as the primary nameserver.
  Edit /etc/resolv.conf directly (bypass systemd-resolved for this task).
  CRITERIA:
  [ ] /etc/resolv.conf contains "nameserver 8.8.8.8"                        --> 60%
  [ ] It's the first nameserver entry                                        --> 40%
  TIME: 8 minutes
  ================================================================================
  TASK 8 — File Sharing: Configure Samba Share (3 points)
  ================================================================================
  Configure a basic Samba share:
  - Share name: public
  - Path: /srv/samba/public
  - Read-only: yes
  - Guest access: allowed
  Create the directory /srv/samba/public and configure /etc/samba/smb.conf.
  Start the smbd service.
  CRITERIA:
  [ ] Directory /srv/samba/public exists                                    --> 20%
  [ ] /etc/samba/smb.conf contains [public] section                         --> 30%
  [ ] Share is configured as read-only and guest ok                         --> 30%
  [ ] smbd service is running                                                --> 20%
  TIME: 15 minutes
  ================================================================================
  TASK 9 — Process Management: Renice Existing Process (3 points)
  ================================================================================
  Find the PID of the `sleep` process owned by user `bob` and change its 
  priority to nice value 10 using `renice`.
  CRITERIA:
  [ ] A sleep process owned by bob exists                                   --> 30%
  [ ] renice command was used (check with ps -l)                            --> 40%
  [ ] Nice value is 10 (ps -l shows NI=10)                                  --> 30%
  TIME: 10 minutes
  ================================================================================
  TASK 10 — System Config: Update Alternatives for Pager (3 points)
  ================================================================================
  Use `update-alternatives` to set `/bin/more` as the default `pager`.
  CRITERIA:
  [ ] update-alternatives --display pager shows /bin/more as current        --> 60%
  [ ] which pager or readlink shows /bin/more                               --> 40%
  TIME: 8 minutes
  ================================================================================
  TASK 11 — Localization: Configure System Locale (3 points)
  ================================================================================
  Change the system locale to `es_ES.UTF-8`.
  Generate the locale if needed and set it as the default.
  CRITERIA:
  [ ] Locale es_ES.UTF-8 is generated (locale -a shows it)                  --> 40%
  [ ] LANG=es_ES.UTF-8 is set in /etc/default/locale                        --> 40%
  [ ] Current session reflects the change (locale shows es_ES)              --> 20%
  TIME: 10 minutes
  ================================================================================
  TASK 12 — Resource Limits: Set nproc Limit (3 points)
  ================================================================================
  Configure a resource limit for all users:
  - Maximum number of processes (nproc): 100
  Create the limit in /etc/security/limits.d/99-nproc.conf
  CRITERIA:
  [ ] File /etc/security/limits.d/99-nproc.conf exists                      --> 30%
  [ ] Contains nproc limit for * (all users)                                --> 40%
  [ ] Limit value is 100                                                     --> 30%
  TIME: 8 minutes
  ================================================================================
  EVIDENCE PIPELINE TO NODE03 (Required for validation)
  ================================================================================
  Run on node01: bash /home/vagrant/generate-evidence.sh
  ================================================================================
  SCORING SUMMARY
  ================================================================================
  Task 1:  3 pts (htop install)       Task 7:  3 pts (DNS resolver)
  Task 2:  3 pts (chage)              Task 8:  3 pts (Samba)
  Task 3:  3 pts (script)             Task 9:  3 pts (renice)
  Task 4:  3 pts (sudoers)            Task 10: 3 pts (alternatives)
  Task 5:  3 pts (at command)         Task 11: 3 pts (locale)
  Task 6:  3 pts (logrotate)          Task 12: 3 pts (nproc limit)
  TOTAL: 36 points
  PASSING (67%): 25 points
  TOTAL TIME: 120 minutes

  When done, run: bash /home/vagrant/validate.sh
  ================================================================================
  TICKET

            # ═══════════════════════════════════════════════════════
            # INITIAL VERIFICATION SCRIPT (verify-013.sh)
            # ═══════════════════════════════════════════════════════
            cat << 'VERIFY' > /tmp/verify-013.sh
  #!/bin/bash
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; RESET='\e[0m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"; PASS="caleston123"; FAIL=0

  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║          VERIFYING SCENARIO MOCK-013                           ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "${YELLOW}[1/7] node02: htop is NOT installed (to be installed)${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "dpkg -l htop 2>/dev/null | grep -q ^ii" 2>/dev/null; then
    echo -e "      ${RED}✗ already installed${RESET}"; FAIL=1
  else
    echo -e "      ${GREEN}✓ OK (not installed)${RESET}"
  fi

  echo -e "${YELLOW}[2/7] node02: /var/log/app.log exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "[ -f /var/log/app.log ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[3/7] node02: atd service is running${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "systemctl is-active atd 2>/dev/null | grep -q active" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[4/7] node02: bob has a sleep process running${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "pgrep -u bob sleep 2>/dev/null" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[5/7] node02: samba packages installed${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "dpkg -l samba 2>/dev/null | grep -q ^ii" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[6/7] node02: locale en_US.UTF-8 is current${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "locale 2>/dev/null | grep -q en_US" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK (default)${RESET}"
  else
    echo -e "      ${RED}✗ already changed${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[7/7] node03: Vault exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/mock-exam-013 ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo ""
  if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ SCENARIO READY — Press ENTER to see the ticket${RESET}"
  else
    echo -e "${RED}⚠️  SOME CHECKS FAILED${RESET}"
  fi
  echo ""
  read -r
  cat /home/vagrant/TICKET_MOCK-013.txt
  VERIFY
            chmod +x /tmp/verify-013.sh
            sed -i '/verify-013/d' /home/vagrant/.bashrc 2>/dev/null || true
            echo 'bash /tmp/verify-013.sh' >> /home/vagrant/.bashrc

            # ═══════════════════════════════════════════════════════
            # EVIDENCE GENERATOR (generate-evidence.sh)
            # ═══════════════════════════════════════════════════════
            cat << 'EVIDENCE' > /home/vagrant/generate-evidence.sh
  #!/bin/bash
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  DEST="node03:/opt/ops-compliance/mock-exam-013/evidence.txt"

  echo "🔍 Collecting evidence from node02..."
  {
    echo "=== EVIDENCE FOR MOCK-013 ==="
    echo "Date: $(date)"
    echo ""

    # TASK 1: htop install
    echo "--- TASK 1: HTOP INSTALL ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "dpkg -l htop 2>/dev/null | grep ^ii; cat /opt/htop-version.txt 2>/dev/null || echo 'file missing'"
    echo ""

    # TASK 2: chage
    echo "--- TASK 2: CHAGE ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo chage -l bob 2>/dev/null || echo 'chage failed'"
    echo ""

    # TASK 3: script
    echo "--- TASK 3: DISK CHECK SCRIPT ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls -l /opt/scripts/disk-check.sh 2>/dev/null; cat /var/log/disk-check.log 2>/dev/null || echo 'log missing'"
    echo ""

    # TASK 4: sudoers
    echo "--- TASK 4: SUDOERS ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /etc/sudoers.d/bob-journal 2>/dev/null; sudo -l -U bob 2>/dev/null | grep journalctl || echo 'rule missing'"
    echo ""

    # TASK 5: at command
    echo "--- TASK 5: AT COMMAND ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "atq 2>/dev/null; for job in \$(atq 2>/dev/null | awk '{print \$1}'); do echo '--- Job \$job ---'; at -c \$job 2>/dev/null | tail -n 5; done"
    echo ""

    # TASK 6: logrotate
    echo "--- TASK 6: LOGROTATE ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /etc/logrotate.d/app-log 2>/dev/null || echo 'config missing'"
    echo ""

    # TASK 7: DNS
    echo "--- TASK 7: DNS RESOLVER ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /etc/resolv.conf 2>/dev/null || echo 'file missing'"
    echo ""

    # TASK 8: samba
    echo "--- TASK 8: SAMBA ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls -ld /srv/samba/public 2>/dev/null; grep -A 10 '\\[public\\]' /etc/samba/smb.conf 2>/dev/null; systemctl is-active smbd 2>/dev/null || echo 'smbd not running'"
    echo ""

    # TASK 9: renice
    echo "--- TASK 9: RENICE ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ps -u bob -l 2>/dev/null | grep sleep || echo 'no sleep process'"
    echo ""

    # TASK 10: alternatives
    echo "--- TASK 10: ALTERNATIVES ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "update-alternatives --display pager 2>/dev/null | head -n 5; readlink -f /usr/bin/pager 2>/dev/null"
    echo ""

    # TASK 11: locale
    echo "--- TASK 11: LOCALE ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "locale -a 2>/dev/null | grep es_ES; cat /etc/default/locale 2>/dev/null; locale 2>/dev/null | head -n 3"
    echo ""

    # TASK 12: nproc limit
    echo "--- TASK 12: NPROC LIMIT ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /etc/security/limits.d/99-nproc.conf 2>/dev/null || echo 'file missing'"
    echo ""

    echo "=== END OF EVIDENCE ==="
  } | sshpass -p $PASS ssh $SSH_OPTS bob@node03 "cat > /opt/ops-compliance/mock-exam-013/evidence.txt"

  if [ $? -eq 0 ]; then
    echo "✅ Evidence saved to $DEST"
  else
    echo "❌ Failed to save evidence"
  fi
  EVIDENCE
            chmod +x /home/vagrant/generate-evidence.sh

            # ═══════════════════════════════════════════════════════
            # VALIDATOR (validate.sh) — evidence‑based
            # ═══════════════════════════════════════════════════════
            cat << 'VALIDATOR' > /home/vagrant/validate.sh
  #!/bin/bash
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; MAGENTA='\e[1;35m'; RESET='\e[0m'; BOLD='\e[1m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  TOTAL=0; MAX=36; PASS_COUNT=0; FAIL_COUNT=0

  EVIDENCE_FILE="/tmp/evidence-$$.txt"
  echo -e "${CYAN}Fetching evidence from node03...${RESET}"
  if ! sshpass -p $PASS scp $SSH_OPTS bob@node03:/opt/ops-compliance/mock-exam-013/evidence.txt "$EVIDENCE_FILE" 2>/dev/null; then
    echo -e "${RED}ERROR: Could not fetch evidence.txt from node03.${RESET}"
    echo -e "${RED}Please run 'bash /home/vagrant/generate-evidence.sh' first.${RESET}"
    exit 1
  fi

  extract_block() {
    local task_num=$1
    local next_num=$((task_num + 1))
    local header_pattern="--- TASK ${task_num}:"
    local next_header_pattern="--- TASK ${next_num}:"
    
    if [ $next_num -le 12 ]; then
      sed -n "/$header_pattern/,/$next_header_pattern/p" "$EVIDENCE_FILE" | sed '$d'
    else
      sed -n "/$header_pattern/,\$p" "$EVIDENCE_FILE"
    fi
  }

  validate_task() {
    local n=$1; local name=$2; local pts=$3; local pattern=$4; local desc=$5
    echo -e "\n${CYAN}┌─ TASK $n: $name ($pts pts) ─${RESET}"
    echo -e "${YELLOW}   $desc${RESET}"
    
    block=$(extract_block $n)
    if [ -z "$block" ]; then
      echo -e "   ${RED}❌ Evidence block for Task $n not found (header missing).${RESET}"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      return
    fi
    
    if echo "$block" | grep -qE "$pattern"; then
      echo -e "   ${GREEN}✅ +$pts pts${RESET}"
      TOTAL=$((TOTAL + pts)); PASS_COUNT=$((PASS_COUNT + 1))
    else
      echo -e "   ${RED}❌ +0 pts${RESET}"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  }

  echo -e "${MAGENTA}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║     🎯 VALIDATOR LFCS — MOCK #013                            ║"
  echo "║        The Alternative Frontier (12 tasks)                   ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "${BOLD}Validating using evidence from node03...${RESET}\n"

  validate_task 1 "htop install" 3 \
    "ii.*htop|htop.*version" \
    "Package installed and version file exists"
  validate_task 2 "chage" 3 \
    "Maximum.*90|Minimum.*7|Warning.*14" \
    "Password aging configured correctly"
  validate_task 3 "disk check script" 3 \
    "disk-check\.sh.*-rwx|/var/log/disk-check\.log" \
    "Script exists, executable, and log created"
  validate_task 4 "sudoers" 3 \
    "bob.*journalctl.*NOPASSWD|journalctl.*NOPASSWD.*bob" \
    "Sudoers rule for journalctl exists"
  validate_task 5 "at command" 3 \
    "atq.*[0-9]|echo.*Scheduled task" \
    "Job scheduled with at"
  validate_task 6 "logrotate" 3 \
    "daily|rotate 7|compress|create.*640" \
    "Logrotate config complete"
  validate_task 7 "DNS resolver" 3 \
    "nameserver 8\.8\.8\.8" \
    "Google DNS configured"
  validate_task 8 "samba" 3 \
    "\\[public\\]|read only.*yes|guest ok.*yes|smbd.*active" \
    "Samba share configured and running"
  validate_task 9 "renice" 3 \
    "sleep.*10|NI.*10|nice.*10" \
    "Process reniced to 10"
  validate_task 10 "alternatives" 3 \
    "pager.*/bin/more|/bin/more.*pager" \
    "Pager set to more"
  validate_task 11 "locale" 3 \
    "es_ES\.UTF-8|LANG=es_ES" \
    "Locale configured to Spanish"
  validate_task 12 "nproc limit" 3 \
    "\\*.*nproc.*100|nproc.*100" \
    "nproc limit set to 100"

  rm -f "$EVIDENCE_FILE"

  PERCENT=$((TOTAL * 100 / MAX))
  echo -e "\n${MAGENTA}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║                    📊 FINAL RESULT                          ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "${BOLD}Tasks passed:${RESET}  ${GREEN}$PASS_COUNT / 12${RESET}"
  echo -e "${BOLD}Tasks failed:${RESET}   ${RED}$FAIL_COUNT / 12${RESET}"
  echo -e "${BOLD}Score:${RESET}         ${CYAN}$TOTAL / $MAX points${RESET}"
  echo -e "${BOLD}Percentage:${RESET}    ${CYAN}$PERCENT%${RESET}"
  echo -e "${BOLD}Passing (67%):${RESET}  ${CYAN}25 points${RESET}"
  echo ""

  if [ $PERCENT -ge 67 ]; then
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           🎉 PASSED! CONGRATULATIONS, BOB! 🎉               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
  else
    echo -e "${RED}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               ❌ NOT PASSED — KEEP GOING! 💪                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
  fi
  echo ""
  VALIDATOR
            chmod +x /home/vagrant/validate.sh

            echo "✅ Ticket + Verification + Validator + Evidence script created."
            echo "🚀 vagrant ssh node01 → automatic verification"
            echo "📝 When done: bash /home/vagrant/validate.sh"
            echo "📦 Generate evidence: bash /home/vagrant/generate-evidence.sh"
          SHELL
        end
      end
    end
  end
---
[[Laboratorios del LFCS]]

---


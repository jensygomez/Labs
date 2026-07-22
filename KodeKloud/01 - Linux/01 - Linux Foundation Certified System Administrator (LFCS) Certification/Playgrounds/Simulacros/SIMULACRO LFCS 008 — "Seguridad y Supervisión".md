---
Titulo: SIMULACRO LFCS 005 — "Incidentes Variados"
Severidad: MEDIA
Ambiente: Produccion
Modulo: LFCS Complete
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-07-20
script vagrant: |-
  # -- mode: ruby --
  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    
    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: ['1G'] }, # extra disk
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
          apt-get install -y -qq sshpass curl acl lvm2 ufw zip tree ntp
        SHELL
        
        # ── NODE02: SERVER WITH 12 INCIDENTS ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🖥️ Configuring node02 with 12 incidents..."
            
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq nginx vim tree
            
            # ── TASK 1: Large files for find ──
            mkdir -p /var/tmp/bigfiles
            dd if=/dev/zero of=/var/tmp/bigfiles/file1.dat bs=1M count=15 2>/dev/null
            dd if=/dev/zero of=/var/tmp/bigfiles/file2.dat bs=1M count=8 2>/dev/null
            dd if=/dev/zero of=/var/tmp/bigfiles/file3.dat bs=1M count=20 2>/dev/null
            dd if=/dev/zero of=/var/tmp/bigfiles/file4.dat bs=1M count=5 2>/dev/null
            
            # ── TASK 2: admins group for user ──
            groupadd -f admins
            
            # ── TASK 3: /dev/vdb unformatted disk ──
            
            # ── TASK 4: Log for logrotate ──
            mkdir -p /var/log/webapp
            cat << 'LOG' > /var/log/webapp/access.log
  192.168.1.10 GET /index.html 200 1024
  192.168.1.11 POST /api/login 401 512
  192.168.1.12 GET /dashboard 200 2048
  LOG
            
            # ── TASK 5: SUID on ping ──
            
            # ── TASK 6: Script for systemd ──
            mkdir -p /opt/scripts
            cat << 'SCRIPT' > /opt/scripts/health-check.sh
  #!/bin/bash
  echo "Health check OK - $(date)" >> /var/log/health-status.log
  SCRIPT
            chmod +x /opt/scripts/health-check.sh
            
            # ── TASK 7: Bob's processes for ps ──
            
            # ── TASK 8: ufw disabled by default ──
            ufw disable 2>/dev/null || true
            
            # ── TASK 9: ss will show existing connections ──
            
            # ── TASK 10: Files for zip ──
            mkdir -p /opt/app-configs
            echo "db_host=10.0.0.5" > /opt/app-configs/database.conf
            echo "cache_ttl=3600" > /opt/app-configs/cache.conf
            echo "log_level=info" > /opt/app-configs/logging.conf
            
            # ── TASK 11: NTP installed (default configuration) ──
            
            # ── TASK 12: Directory for SGID ──
            mkdir -p /opt/shared
            chown root:admins /opt/shared
            chmod 775 /opt/shared
            
            # active nginx
            systemctl enable nginx
            systemctl start nginx
            
            echo "✅ node02 configured with 12 incidents"
          SHELL
        end
        
        # ── NODE03: VAULT ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparing vault..."
            mkdir -p /opt/ops-compliance/mock-exam-008
            chown -R bob:bob /opt/ops-compliance
            chmod -R 755 /opt/ops-compliance
            echo "✅ Vault ready at /opt/ops-compliance/mock-exam-008/"
          SHELL
        end
        
        # ── NODE01: TICKET + VERIFICATION + VALIDATOR + EVIDENCE ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generating Ticket, verification, validator, and evidence script on node01..."
            
            # ═══════════════════════════════════════════════════════
            # TICKET
            # ═══════════════════════════════════════════════════════
            cat << 'TICKET' > /home/vagrant/TICKET_MOCK_EXAM-008.txt
  ================================================================================
  TICKET MOCK_EXAM-008  │  Severity: MEDIUM  │  Environment: PRODUCTION
  🔐 MOCK EXAM-008 — Security and Supervision (12 Tasks)
  Module: LFCS Complete  │  Difficulty: 3/10  │  Level: L2
  Control Location:      node01  (Administrator Workstation — bob)
  Server Node:           node02  (Ubuntu 22.04)
  Destination Vault:     node03  (/opt/ops-compliance/mock-exam-008/)
  Cluster Password:      caleston123

  A server on node02 requires 12 system administration tasks, focused on security,
  monitoring, and system operations. Each task addresses a different domain.
  Manage your time: maximum 8-10 minutes per task. If you get stuck, move to the next one.

  ================================================================================
  TASK 1 — Essential Commands: Find and Compress (weight 3 points)
  ================================================================================
  The development team wants to free up space by compressing large files.

  On node02:
  1. Find all files larger than 10M in /var/tmp/bigfiles
  2. Compress each one with gzip (they must remain as .gz files)
  3. Do not delete the originals (gzip replaces them by default)

  CRITERIA:
    [ ] Files >10M were compressed (.gz exist)                               --> 40%
    [ ] Files <=10M remain uncompressed                                      --> 30%
    [ ] Total files count is 4, large files count is 2 (file1, file3)       --> 30%

  MAX TIME: 10 minutes

  ================================================================================
  TASK 2 — Users/Groups: User with Specific UID (weight 3 points)
  ================================================================================
  A user with a fixed UID is required for integration with an external system.

  On node02:
  1. Create a user named "appuser" with UID=1500
  2. Shell: /bin/bash
  3. Primary group: appuser (created automatically)
  4. Secondary group: admins
  5. Password: caleston123

  CRITERIA:
    [ ] User appuser exists with UID=1500                                    --> 40%
    [ ] Primary group is appuser (same name)                                 --> 30%
    [ ] Belongs to secondary group admins                                    --> 30%

  MAX TIME: 10 minutes

  ================================================================================
  TASK 3 — Storage: Format and Mount XFS (weight 3 points)
  ================================================================================
  An XFS filesystem is required for application data.

  On node02:
  1. Disk /dev/vdb is available (unformatted)
  2. Format /dev/vdb as XFS (mkfs.xfs)
  3. Create directory /mnt/data
  4. Mount /dev/vdb on /mnt/data (temporary mount, fstab not required)

  CRITERIA:
    [ ] /dev/vdb is formatted as XFS (blkid)                                 --> 40%
    [ ] /mnt/data exists                                                      --> 20%
    [ ] /dev/vdb is mounted on /mnt/data                                     --> 40%

  MAX TIME: 10 minutes

  ================================================================================
  TASK 4 — Operations/logrotate: Log Rotation (weight 3 points)
  ================================================================================
  The file /var/log/webapp/access.log grows quickly and requires daily rotation.

  On node02:
  1. Create a configuration file at /etc/logrotate.d/webapp
  2. Rotate logs daily (daily)
  3. Keep 7 rotations (rotate 7)
  4. Compress rotated logs (compress)
  5. Do not use create (optional, not strictly required)

  CRITERIA:
    [ ] File /etc/logrotate.d/webapp exists                                 --> 30%
    [ ] Contains "daily", "rotate 7", and "compress"                        --> 50%
    [ ] Path /var/log/webapp/access.log is specified                         --> 20%

  MAX TIME: 10 minutes

  ================================================================================
  TASK 5 — Security/SUID: Set SUID on Binary (weight 3 points)
  ================================================================================
  For security requirements, the ping command must be executable with privileges.

  On node02:
  1. Verify if /usr/bin/ping has SUID permissions (chmod u+s)
  2. If it does not, enable it
  3. Verify that the SUID bit is set (ls -l)

  CRITERIA:
    [ ] /usr/bin/ping has the SUID bit set (s in owner permissions)           --> 100%

  MAX TIME: 5 minutes

  ================================================================================
  TASK 6 — Systemd: Create a Service (weight 3 points)
  ================================================================================
  A service is required to execute a health script every 5 minutes.

  On node02:
  1. Script /opt/scripts/health-check.sh already exists and is executable
  2. Create a systemd unit file at /etc/systemd/system/health-check.service
  3. Execute the script as a simple service (Type=simple)
  4. Enable and start the service (systemctl enable --now)
  5. Verify that it is active (systemctl status)

  CRITERIA:
    [ ] Unit file exists at the correct path                                 --> 30%
    [ ] Contains basic directives (ExecStart, Type, etc.)                    --> 30%
    [ ] Service is enabled and active                                        --> 40%

  MAX TIME: 12 minutes

  ================================================================================
  TASK 7 — Monitoring/ps: Count User Processes (weight 3 points)
  ================================================================================
  Need to determine how many processes belonging to user "bob" are running.

  On node02:
  1. Use ps and grep to count bob's processes (excluding the grep process itself)
  2. Save the count into /opt/bob-process-count.txt

  CRITERIA:
    [ ] /opt/bob-process-count.txt exists                                    --> 30%
    [ ] Contains only an integer number                                      --> 30%
    [ ] The count is correct (at least 1)                                    --> 40%

  MAX TIME: 10 minutes

  ================================================================================
  TASK 8 — Networking/ufw: Firewall for SSH (weight 3 points)
  ================================================================================
  SSH access must be restricted to allow incoming connections only from the host machine (IP 192.168.122.1).

  On node02:
  1. Enable ufw if disabled
  2. Configure a rule to allow SSH only from 192.168.122.1
  3. Deny SSH from any other IP address
  4. Enable/apply firewall rules (ufw enable)

  CRITERIA:
    [ ] ufw is active (ufw status)                                           --> 20%
    [ ] Rule exists allowing SSH from 192.168.122.1                           --> 40%
    [ ] No rule allows SSH from any IP (or explicitly denied)               --> 40%

  MAX TIME: 10 minutes

  ================================================================================
  TASK 9 — Networking/ss: Show Established TCP Connections (weight 3 points)
  ================================================================================
  The network team needs to view active TCP connections.

  On node02:
  1. Use ss to list all active TCP connections in ESTABLISHED status
  2. Save output to /opt/tcp-established.txt

  CRITERIA:
    [ ] /opt/tcp-established.txt exists                                      --> 30%
    [ ] Contains lines with ESTAB connections                                --> 40%
    [ ] Command ss was used (not netstat)                                    --> 30%

  MAX TIME: 8 minutes

  ================================================================================
  TASK 10 — Packaging/zip: Compress Configurations (weight 3 points)
  ================================================================================
  A zip backup of application configuration files is required.

  On node02:
  1. Directory /opt/app-configs/ contains .conf files
  2. Create /opt/configs.zip with all content inside /opt/app-configs/
  3. Verify that the zip archive is valid (unzip -t)

  CRITERIA:
    [ ] /opt/configs.zip exists                                               --> 40%
    [ ] Valid zip file (unzip -t)                                            --> 30%
    [ ] Contains .conf files (database.conf, cache.conf, logging.conf)       --> 30%

  MAX TIME: 10 minutes

  ================================================================================
  TASK 11 — Time/NTP: Synchronize Time (weight 3 points)
  ================================================================================
  The server time must be synchronized using NTP servers.

  On node02:
  1. Ensure NTP service is installed (already installed)
  2. Verify that it is active (systemctl status ntp or systemd-timesyncd)
  3. If inactive, start it and verify clock synchronization
  4. Save the output of `timedatectl show` into /opt/time-status.txt

  CRITERIA:
    [ ] NTP service active (or systemd-timesyncd)                            --> 40%
    [ ] timedatectl shows "synchronized: yes"                                --> 30%
    [ ] /opt/time-status.txt contains timedatectl output                     --> 30%

  MAX TIME: 10 minutes

  ================================================================================
  TASK 12 — Permissions/SGID: Group Inheritance (weight 3 points)
  ================================================================================
  All files created inside /opt/shared must inherit group ownership "admins".

  On node02:
  1. Directory /opt/shared already exists (owned by root:admins, permissions 775)
  2. Set the SGID bit on the directory (chmod g+s)
  3. Create a test file inside to verify it inherits the group ownership

  CRITERIA:
    [ ] /opt/shared has the SGID bit set (s in group permissions)            --> 40%
    [ ] New files created inside belong to the admins group                  --> 40%
    [ ] getfacl or ls -ld displays SGID bit                                  --> 20%

  MAX TIME: 10 minutes

  ================================================================================
  EVIDENCE PIPELINE TO NODE03 (OPTIONAL — NO POINTS)
  ================================================================================
  If you wish to automate evidence collection, run on node01:
    bash /home/vagrant/generate-evidence.sh

  This will collect output from all 12 tasks and copy them to:
    node03:/opt/ops-compliance/mock-exam-008/evidence.txt

  Optional, but helps complete full workflow.

  ================================================================================
  SCORING SUMMARY
  ================================================================================
  Task 1:  3 pts (Essential - find/gzip)
  Task 2:  3 pts (Users/Groups - Specific UID)
  Task 3:  3 pts (Storage - XFS)
  Task 4:  3 pts (Operations - logrotate)
  Task 5:  3 pts (Security - SUID)
  Task 6:  3 pts (Systemd - Service)
  Task 7:  3 pts (Monitoring - ps)
  Task 8:  3 pts (Networking - ufw)
  Task 9:  3 pts (Networking - ss)
  Task 10: 3 pts (Packaging - zip)
  Task 11: 3 pts (Time - NTP)
  Task 12: 3 pts (Permissions - SGID)
  TOTAL: 36 points
  MINIMUM TO PASS (67%): 25 points

  MAX TOTAL TIME: 120 minutes

  When finished, run: bash /home/vagrant/validate.sh
  ================================================================================
  TICKET

            # ═══════════════════════════════════════════════════════
            # INITIAL VERIFICATION SCRIPT
            # ═══════════════════════════════════════════════════════
            cat << 'VERIFY' > /tmp/verify-008.sh
  #!/bin/bash
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; RESET='\e[0m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"; PASS="caleston123"; FAIL=0

  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║          ENVIRONMENT VERIFICATION MOCK-EXAM-008               ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "${YELLOW}[1/8] node02: Large files in /var/tmp/bigfiles${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls /var/tmp/bigfiles/file*.dat 2>/dev/null | wc -l | grep -q 4" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[2/8] node02: admins group exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "getent group admins >/dev/null" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[3/8] node02: /dev/vdb unformatted disk${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo blkid /dev/vdb 2>/dev/null | grep -q ." 2>/dev/null; then
    echo -e "      ${RED}✗ Disk already formatted${RESET}"; FAIL=1
  else
    echo -e "      ${GREEN}✓ OK (raw)${RESET}"
  fi

  echo -e "${YELLOW}[4/8] node02: Log /var/log/webapp/access.log exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "[ -f /var/log/webapp/access.log ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[5/8] node02: Script health-check.sh exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "[ -x /opt/scripts/health-check.sh ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[6/8] node02: Directory /opt/app-configs with .conf files${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls /opt/app-configs/*.conf 2>/dev/null | wc -l | grep -q 3" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[7/8] node02: Directory /opt/shared exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "[ -d /opt/shared ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[8/8] node03: Vault exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/mock-exam-008 ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo ""
  if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ ENVIRONMENT READY — Press ENTER to view the ticket${RESET}"
  else
    echo -e "${RED}⚠️  SOME CHECKS FAILED${RESET}"
  fi
  echo ""
  read -r
  cat /home/vagrant/TICKET_MOCK_EXAM-008.txt
  VERIFY
            chmod +x /tmp/verify-008.sh
            sed -i '/verify-008/d' /home/vagrant/.bashrc 2>/dev/null || true
            echo 'bash /tmp/verify-008.sh' >> /home/vagrant/.bashrc

            # ═══════════════════════════════════════════════════════
            # FINAL VALIDATOR (validate.sh)
            # ═══════════════════════════════════════════════════════
            cat << 'VALIDATOR' > /home/vagrant/validate.sh
  #!/bin/bash
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; MAGENTA='\e[1;35m'; RESET='\e[0m'; BOLD='\e[1m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  TOTAL=0; MAX=36; PASS_COUNT=0; FAIL_COUNT=0

  run02() { sshpass -p $PASS ssh $SSH_OPTS bob@node02 "$1" 2>/dev/null; }

  check() {
    local n=$1; local name=$2; local pts=$3; local cmd=$4; local desc=$5
    echo -e "\n${CYAN}┌─ TASK $n: $name ($pts pts) ─${RESET}"
    echo -e "${YELLOW}   $desc${RESET}"
    if run02 "$cmd" >/dev/null 2>&1; then
      echo -e "   ${GREEN}✅ +$pts pts${RESET}"
      TOTAL=$((TOTAL + pts)); PASS_COUNT=$((PASS_COUNT + 1))
    else
      echo -e "   ${RED}❌ +0 pts${RESET}"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  }

  echo -e "${MAGENTA}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║     🎯 LFCS VALIDATOR — MOCK EXAM #008                      ║"
  echo "║        Security and Supervision (12 tasks)                  ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "${BOLD}Validating on node02...${RESET}\n"

  # T1: find + gzip
  check 1 "large find/gzip" 3 \
    "[ -f /var/tmp/bigfiles/file1.dat.gz ] && [ -f /var/tmp/bigfiles/file3.dat.gz ] && [ -f /var/tmp/bigfiles/file2.dat ] && [ -f /var/tmp/bigfiles/file4.dat ] && [ ! -f /var/tmp/bigfiles/file1.dat ] && [ ! -f /var/tmp/bigfiles/file3.dat ]" \
    "Files >10M compressed (.gz), <=10M uncompressed (file2 and file4)"

  # T2: User appuser UID 1500 + group admins
  check 2 "User appuser" 3 \
    "id -u appuser 2>/dev/null | grep -q 1500 && id -g appuser 2>/dev/null | grep -q appuser && id -Gn appuser 2>/dev/null | grep -q admins" \
    "User appuser UID=1500, primary group appuser, secondary admins"

  # T3: XFS and mount
  echo -e "\n${CYAN}┌─ TASK 3: XFS and mount (3 pts) ─${RESET}"
  xfs=$(run02 "sudo blkid /dev/vdb 2>/dev/null | grep -q 'TYPE=\"xfs\"' && echo ok")
  mnt=$(run02 "mount | grep -q '/dev/vdb on /mnt/data' && echo ok")
  if [ "$xfs" = "ok" ] && [ "$mnt" = "ok" ]; then
    echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$xfs" != "ok" ] && echo -e "   ${RED}  ✗ Not XFS${RESET}"
    [ "$mnt" != "ok" ] && echo -e "   ${RED}  ✗ Not mounted on /mnt/data${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # T4: logrotate
  check 4 "logrotate" 3 \
    "[ -f /etc/logrotate.d/webapp ] && grep -q 'daily' /etc/logrotate.d/webapp && grep -q 'rotate 7' /etc/logrotate.d/webapp && grep -q 'compress' /etc/logrotate.d/webapp" \
    "File /etc/logrotate.d/webapp with daily, rotate 7, compress"

  # T5: SUID on ping
  check 5 "SUID ping" 3 \
    "[ -u /usr/bin/ping ]" \
    "SUID bit active on /usr/bin/ping"

  # T6: Systemd service
  echo -e "\n${CYAN}┌─ TASK 6: Systemd service (3 pts) ─${RESET}"
  srv=$(run02 "[ -f /etc/systemd/system/health-check.service ] && echo ok")
  act=$(run02 "systemctl is-active --quiet health-check.service && echo ok")
  if [ "$srv" = "ok" ] && [ "$act" = "ok" ]; then
    echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$srv" != "ok" ] && echo -e "   ${RED}  ✗ Unit file does not exist${RESET}"
    [ "$act" != "ok" ] && echo -e "   ${RED}  ✗ Service not active${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # T7: ps count bob
  check 7 "ps count bob" 3 \
    "[ -f /opt/bob-process-count.txt ] && [ \$(cat /opt/bob-process-count.txt | tr -d '[:space:]' | grep -E '^[0-9]+$') ] && [ \$(cat /opt/bob-process-count.txt | tr -d '[:space:]') -ge 1 ]" \
    "/opt/bob-process-count.txt with number >= 1 (digits only)"

  # T8: ufw SSH rule
  echo -e "\n${CYAN}┌─ TASK 8: ufw SSH from specific IP (3 pts) ─${RESET}"
  ufw_active=$(run02 "sudo ufw status 2>/dev/null | grep -q 'Status: active' && echo ok")
  rule_allow=$(run02 "sudo ufw status 2>/dev/null | grep -q '22.*ALLOW.*192.168.122.1' && echo ok")
  rule_deny=$(run02 "sudo ufw status 2>/dev/null | grep -q '22.*DENY' || echo ok")
  if [ "$ufw_active" = "ok" ] && [ "$rule_allow" = "ok" ]; then
    allow_any=$(run02 "sudo ufw status 2>/dev/null | grep -E '22.*ALLOW.*[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | grep -v '192.168.122.1' | wc -l")
    if [ "$allow_any" -eq 0 ]; then
      echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
    else
      echo -e "   ${RED}❌ +0 pts (there are other rules allowing SSH)${RESET}"; FAIL_COUNT=$((FAIL_COUNT+1))
    fi
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$ufw_active" != "ok" ] && echo -e "   ${RED}  ✗ ufw not active${RESET}"
    [ "$rule_allow" != "ok" ] && echo -e "   ${RED}  ✗ No allow rule from 192.168.122.1${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # T9: ss established
  check 9 "ss established" 3 \
    "[ -f /opt/tcp-established.txt ] && grep -q 'ESTAB' /opt/tcp-established.txt" \
    "File /opt/tcp-established.txt containing ESTAB connections"

  # T10: zip
  echo -e "\n${CYAN}┌─ TASK 10: zip (3 pts) ─${RESET}"
  z1=$(run02 "[ -f /opt/configs.zip ] && echo ok")
  z2=$(run02 "unzip -t /opt/configs.zip 2>/dev/null | grep -q 'No errors' && echo ok")
  z3=$(run02 "unzip -l /opt/configs.zip 2>/dev/null | grep -q database.conf && unzip -l /opt/configs.zip 2>/dev/null | grep -q cache.conf && unzip -l /opt/configs.zip 2>/dev/null | grep -q logging.conf && echo ok")
  if [ "$z1" = "ok" ] && [ "$z2" = "ok" ] && [ "$z3" = "ok" ]; then
    echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$z1" != "ok" ] && echo -e "   ${RED}  ✗ File does not exist${RESET}"
    [ "$z2" != "ok" ] && echo -e "   ${RED}  ✗ Not a valid zip archive${RESET}"
    [ "$z3" != "ok" ] && echo -e "   ${RED}  ✗ Missing .conf files${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # T11: NTP / timedatectl
  echo -e "\n${CYAN}┌─ TASK 11: NTP (3 pts) ─${RESET}"
  ntp_active=$(run02 "systemctl is-active --quiet ntp 2>/dev/null && echo ok || systemctl is-active --quiet systemd-timesyncd 2>/dev/null && echo ok")
  sync=$(run02 "timedatectl 2>/dev/null | grep -q 'synchronized: yes' && echo ok")
  file=$(run02 "[ -f /opt/time-status.txt ] && echo ok")
  if { [ "$ntp_active" = "ok" ] || [ "$sync" = "ok" ]; } && [ "$file" = "ok" ]; then
    echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$ntp_active" != "ok" ] && echo -e "   ${RED}  ✗ NTP service not active${RESET}"
    [ "$sync" != "ok" ] && echo -e "   ${RED}  ✗ Not synchronized${RESET}"
    [ "$file" != "ok" ] && echo -e "   ${RED}  ✗ /opt/time-status.txt does not exist${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # T12: SGID on /opt/shared
  echo -e "\n${CYAN}┌─ TASK 12: SGID (3 pts) ─${RESET}"
  sgid=$(run02 "ls -ld /opt/shared 2>/dev/null | grep -q '^d...s' && echo ok")
  run02 "touch /opt/shared/testfile 2>/dev/null" >/dev/null
  group=$(run02 "ls -l /opt/shared/testfile 2>/dev/null | awk '{print \$4}' | grep -q 'admins' && echo ok")
  if [ "$sgid" = "ok" ] && [ "$group" = "ok" ]; then
    echo -e "   ${GREEN}✅ +3 pts${RESET}"; TOTAL=$((TOTAL+3)); PASS_COUNT=$((PASS_COUNT+1))
  else
    echo -e "   ${RED}❌ +0 pts${RESET}"
    [ "$sgid" != "ok" ] && echo -e "   ${RED}  ✗ Missing SGID bit${RESET}"
    [ "$group" != "ok" ] && echo -e "   ${RED}  ✗ Test file did not inherit admins group${RESET}"
    FAIL_COUNT=$((FAIL_COUNT+1))
  fi

  # ═══════════════════════════════════════════════════════════════
  # FINAL RESULT
  # ═══════════════════════════════════════════════════════════════
  PERCENT=$((TOTAL * 100 / MAX))

  echo -e "\n${MAGENTA}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║                    📊 FINAL RESULT                           ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "${BOLD}Passed tasks:${RESET}  ${GREEN}$PASS_COUNT / 12${RESET}"
  echo -e "${BOLD}Failed tasks:${RESET}  ${RED}$FAIL_COUNT / 12${RESET}"
  echo -e "${BOLD}Score:${RESET}         ${CYAN}$TOTAL / $MAX points${RESET}"
  echo -e "${BOLD}Percentage:${RESET}    ${CYAN}$PERCENT%${RESET}"
  echo -e "${BOLD}Passing score (67%):${RESET} ${CYAN}25 points${RESET}"
  echo ""

  if [ $PERCENT -ge 67 ]; then
    echo -e "${GREEN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           🎉 PASSED! CONGRATULATIONS, BOB! 🎉              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
  else
    echo -e "${RED}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║             ❌ FAILED — Keep going! 💪                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
  fi
  echo ""
  VALIDATOR
            chmod +x /home/vagrant/validate.sh
            
            # ═══════════════════════════════════════════════════════
            # OPTIONAL EVIDENCE SCRIPT
            # ═══════════════════════════════════════════════════════
            cat << 'EVIDENCE' > /home/vagrant/generate-evidence.sh
  #!/bin/bash
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  DEST="node03:/opt/ops-compliance/mock-exam-008/evidence.txt"

  echo "🔍 Collecting evidence from node02..."
  {
    echo "=== MOCK-EXAM-008 EVIDENCE ==="
    echo "Date: $(date)"
    echo ""
    echo "--- Task 1: ls -l /var/tmp/bigfiles ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls -l /var/tmp/bigfiles 2>/dev/null || echo 'Does not exist'"
    echo ""
    echo "--- Task 2: id appuser ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "id appuser 2>/dev/null || echo 'Does not exist'"
    echo ""
    echo "--- Task 3: sudo blkid /dev/vdb; mount | grep vdb ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo blkid /dev/vdb 2>/dev/null; mount | grep vdb 2>/dev/null || echo 'Not mounted'"
    echo ""
    echo "--- Task 4: cat /etc/logrotate.d/webapp ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /etc/logrotate.d/webapp 2>/dev/null || echo 'Does not exist'"
    echo ""
    echo "--- Task 5: ls -l /usr/bin/ping ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls -l /usr/bin/ping 2>/dev/null || echo 'Does not exist'"
    echo ""
    echo "--- Task 6: systemctl status health-check.service ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "systemctl status health-check.service 2>/dev/null || echo 'Does not exist'"
    echo ""
    echo "--- Task 7: cat /opt/bob-process-count.txt ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /opt/bob-process-count.txt 2>/dev/null || echo 'Does not exist'"
    echo ""
    echo "--- Task 8: sudo ufw status ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo ufw status 2>/dev/null || echo 'ufw unavailable'"
    echo ""
    echo "--- Task 9: head /opt/tcp-established.txt ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "head /opt/tcp-established.txt 2>/dev/null || echo 'Does not exist'"
    echo ""
    echo "--- Task 10: unzip -l /opt/configs.zip ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "unzip -l /opt/configs.zip 2>/dev/null || echo 'Does not exist or invalid'"
    echo ""
    echo "--- Task 11: cat /opt/time-status.txt; timedatectl ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /opt/time-status.txt 2>/dev/null; timedatectl 2>/dev/null"
    echo ""
    echo "--- Task 12: ls -ld /opt/shared; ls -l /opt/shared/testfile ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls -ld /opt/shared 2>/dev/null; ls -l /opt/shared/testfile 2>/dev/null || echo 'No testfile'"
    echo ""
    echo "=== END OF EVIDENCE ==="
  } | sshpass -p $PASS ssh $SSH_OPTS bob@node03 "cat > /opt/ops-compliance/mock-exam-008/evidence.txt"

  if [ $? -eq 0 ]; then
    echo "✅ Evidence saved to $DEST"
  else
    echo "❌ Failed to save evidence"
  fi
  EVIDENCE
            chmod +x /home/vagrant/generate-evidence.sh
            
            echo "✅ Ticket + Verification + Validator + Evidence script created."
            echo "🚀 vagrant ssh node01 → automatic verification"
            echo "📝 When done: bash /home/vagrant/validate.sh"
            echo "📦 (Optional) Send evidence: bash /home/vagrant/generate-evidence.sh"
          SHELL
        end
      end
    end
  end
---
[[Laboratorios del LFCS]]

---


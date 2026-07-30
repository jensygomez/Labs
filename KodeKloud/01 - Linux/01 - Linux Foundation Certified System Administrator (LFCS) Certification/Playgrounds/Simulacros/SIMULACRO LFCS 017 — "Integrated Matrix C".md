---
Titulo: SIMULACRO LFCS 016 — "Integrated Matrix B"
Severidad: MEDIA
Ambiente: Produccion
Modulo: LFCS Complete
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-07-30
Script Vagrant: |-
  # -- mode: ruby --
  # vi: set ft=ruby :
  ENV['VAGRANT_NO_PARALLEL'] = 'yes'
  Vagrant.configure("2") do |config|
    config.vm.box = "almalinux/9"
    config.ssh.insert_key = false

    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: ['1G'] } # Extra disk for Quotas task
    ]

    nodes.each do |node|
      config.vm.define node[:name] do |node_config|
        node_config.vm.hostname = node[:name]
        
        node_config.vm.network "private_network",
          ip: node[:ip],
          libvirt__network_name: "mgmt-net",
          libvirt__dhcp_enabled: false

        node_config.vm.provider "libvirt" do |lv|
          lv.memory = 2048
          lv.cpus = 2
          lv.driver = "kvm"
          node[:extra_disks].each do |size|
            lv.storage :file, :size => size, :type => 'qcow2'
          end
        end

        # ── GENERAL PROVISIONING (all nodes) ──
        node_config.vm.provision "shell", inline: <<-SHELL
          echo "🔧 Configuring #{node[:name]}..."
          for host in node01 node02; do
            sed -i "/$host/d" /etc/hosts
          done
          cat << 'HOSTS' >> /etc/hosts
  192.168.122.11 node01
  192.168.122.12 node02
  HOSTS
          useradd -m -s /bin/bash bob 2>/dev/null || true
          echo 'bob:caleston123' | chpasswd
          echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
          chmod 0440 /etc/sudoers.d/bob
          
          dnf install -y -q epel-release >/dev/null 2>&1
          dnf install -y -q sshpass curl acl >/dev/null 2>&1
          systemctl enable --now sshd >/dev/null 2>&1
          systemctl disable --now firewalld >/dev/null 2>&1 || true
        SHELL

        # ── NODE02: SERVER PREPARATION ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🖥️ Configuring node02 for MOCK-017..."
            
            # Install required packages for the 12 tasks
            dnf install -y -q sssd authselect nginx podman quota logrotate python3 >/dev/null 2>&1
            
            # Prepare dummy backend for Nginx reverse proxy (Task 4)
            nohup python3 -m http.server 5000 >/dev/null 2>&1 &
            
            # Prepare dummy log for logrotate (Task 11)
            touch /var/log/custom_app.log
            
            # Prepare directory for Podman volume (Task 9)
            mkdir -p /var/log/app_data
            chmod 777 /var/log/app_data
            
            # Ensure SELinux is enforcing (Task 6)
            setenforce 1 || true
            sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
            
            echo "✅ node02 configured for MOCK-017"
          SHELL
        end

        # ── NODE01: TICKET + VERIFICATION + VALIDATOR ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generating Ticket, verification, and validator on node01..."
            
            cat << 'TICKET' > /home/vagrant/TICKET_MOCK-017.txt
  ================================================================================
  TICKET MOCK-017   |  Severity: MEDIUM  |  Environment: PRODUCTION
  🔐 MOCK-017 — Integrated Matrix C (12 Tasks)  |  AlmaLinux 9
  Module: LFCS Complete  |  Difficulty: 4/10  |  Level: L2
  Control Station:    node01  (Administrator — bob)
  Server Node:        node02  (AlmaLinux 9)
  Cluster Password:   caleston123
  ================================================================================
  ⚠️  PRE-REQUISITE: SSH KEY SETUP (MANDATORY BEFORE STARTING) ⚠️
  Before starting the tasks, you must establish passwordless SSH from node01 to 
  node02 for the 'bob' user.
  1. On node01, generate an SSH key pair for bob: `ssh-keygen -t rsa -N ""`
  2. Copy the public key to node02: `ssh-copy-id bob@node02` (Password: caleston123)
  3. Verify you can connect without a password: `ssh bob@node02`
  ================================================================================
  📝 EVIDENCE BASED VALIDATION RULE:
  For EVERY task below, you MUST save the specific output or configuration 
  content to the designated evidence file (e.g., /tmp/task_01.evidence). 
  The validator will ONLY check these files.
  ================================================================================
  TASK 1 — Operations: GRUB Boot Parameters (3 points)
  ================================================================================
  On node02, use `grubby` to add the kernel parameter `console=ttyS0` to the 
  default boot entry. Update the bootloader configuration.
  CRITERIA:
  [ ] Default kernel parameters include console=ttyS0                       --> 100%
  EVIDENCE: Save output of `grubby --info=DEFAULT | grep args` to /tmp/task_01.evidence
  TIME: 8 minutes
  ================================================================================
  TASK 2 — Users: SSSD & Authselect (3 points)
  ================================================================================
  On node02, install `sssd` and `authselect`. Apply the `sssd` authselect profile 
  with the `with-mkhomedir` feature. Enable and start the `sssd` service.
  CRITERIA:
  [ ] Authselect profile is set to sssd with with-mkhomedir                   --> 50%
  [ ] sssd service is enabled and running                                     --> 50%
  EVIDENCE: Save output of `authselect current` AND `systemctl is-enabled sssd` to /tmp/task_02.evidence
  TIME: 10 minutes
  ================================================================================
  TASK 3 — Storage: Disk Quotas (3 points)
  ================================================================================
  On node02, format the extra disk `/dev/vdb` as `ext4`. Mount it persistently 
  on `/mnt/quota` with the `usrquota` option. Enable quotas, and set a soft limit 
  of 100M (102400 blocks) and hard limit of 120M for user `bob`.
  CRITERIA:
  [ ] /dev/vdb mounted on /mnt/quota with usrquota in fstab                   --> 50%
  [ ] User bob has soft limit 100M configured                                 --> 50%
  EVIDENCE: Save output of `repquota -a | grep bob` to /tmp/task_03.evidence
  TIME: 15 minutes
  ================================================================================
  TASK 4 — Networking: Nginx Reverse Proxy (3 points)
  ================================================================================
  On node02, configure Nginx to act as a reverse proxy. Requests to the location 
  `/app` must be proxied to `http://127.0.0.1:5000`. Ensure nginx is running.
  CRITERIA:
  [ ] Nginx config contains location /app with proxy_pass to 127.0.0.1:5000   --> 100%
  EVIDENCE: Save output of `nginx -T 2>/dev/null | grep -A2 'location /app'` to /tmp/task_04.evidence
  TIME: 12 minutes
  ================================================================================
  TASK 5 — Essential Commands: SUID Audit (3 points)
  ================================================================================
  On node02, find all files with the SUID bit set in `/usr/bin` and save the 
  absolute paths to `/tmp/suid_audit.txt`.
  CRITERIA:
  [ ] /tmp/suid_audit.txt exists and contains SUID files from /usr/bin        --> 100%
  EVIDENCE: Save the first 3 lines of the file using `head -n 3 /tmp/suid_audit.txt` to /tmp/task_05.evidence
  TIME: 8 minutes
  ================================================================================
  TASK 6 — Security: SELinux Booleans (3 points)
  ================================================================================
  On node02, permanently enable the SELinux boolean `httpd_can_network_connect`.
  CRITERIA:
  [ ] httpd_can_network_connect is set to 'on' permanently                    --> 100%
  EVIDENCE: Save output of `getsebool httpd_can_network_connect` to /tmp/task_06.evidence
  TIME: 8 minutes
  ================================================================================
  TASK 7 — Networking: Persistent Static Route (3 points)
  ================================================================================
  On node02, add a persistent static route for the network `192.168.100.0/24` 
  via the gateway `192.168.122.1` using `nmcli`.
  CRITERIA:
  [ ] Route 192.168.100.0/24 via 192.168.122.1 exists persistently          --> 100%
  EVIDENCE: Save output of `nmcli con show | grep -A2 'ipv4.routes'` or `ip route | grep 192.168.100` to /tmp/task_07.evidence
  TIME: 10 minutes
  ================================================================================
  TASK 8 — Operations: System Cron (3 points)
  ================================================================================
  On node02, create a system cron job in `/etc/cron.d/mock17_cleanup` that runs 
  the command `echo "cleanup" > /dev/null` every 15 minutes as root.
  CRITERIA:
  [ ] /etc/cron.d/mock17_cleanup exists with correct syntax and schedule      --> 100%
  EVIDENCE: Save the content of the cron file using `cat /etc/cron.d/mock17_cleanup` to /tmp/task_08.evidence
  TIME: 8 minutes
  ================================================================================
  TASK 9 — Containers: Podman Persistent Volume (3 points)
  ================================================================================
  On node02, run a rootless Podman container named `app_logger` using the `alpine` 
  image. Map the host directory `/var/log/app_data` to `/data` inside the container. 
  The container should just run `sleep infinity`.
  CRITERIA:
  [ ] Container 'app_logger' is running with correct volume mapping           --> 100%
  EVIDENCE: Save output of `podman ps --format "{{.Names}} {{.Mounts}}"` to /tmp/task_09.evidence
  TIME: 12 minutes
  ================================================================================
  TASK 10 — Users: Global Environment Variable (3 points)
  ================================================================================
  On node02, create a script `/etc/profile.d/app_env.sh` that exports the 
  environment variable `APP_STAGE=prod` for all users.
  CRITERIA:
  [ ] /etc/profile.d/app_env.sh exists and exports APP_STAGE=prod             --> 100%
  EVIDENCE: Save the content of the file using `cat /etc/profile.d/app_env.sh` to /tmp/task_10.evidence
  TIME: 8 minutes
  ================================================================================
  TASK 11 — Operations: Logrotate Configuration (3 points)
  ================================================================================
  On node02, configure logrotate for `/var/log/custom_app.log`. It should rotate 
  daily, keep 7 rotations, compress old logs, and create new files with 640 perms.
  CRITERIA:
  [ ] Logrotate config for custom_app.log exists with correct directives      --> 100%
  EVIDENCE: Save the content of the logrotate config file to /tmp/task_11.evidence
  TIME: 10 minutes
  ================================================================================
  TASK 12 — Essential Commands: Tar Archive (3 points)
  ================================================================================
  On node02, create a compressed tar archive of the `/etc/ssh` directory and 
  save it as `/tmp/ssh_backup.tar.gz`.
  CRITERIA:
  [ ] /tmp/ssh_backup.tar.gz exists and contains /etc/ssh files               --> 100%
  EVIDENCE: Save output of `tar -tzf /tmp/ssh_backup.tar.gz | wc -l` to /tmp/task_12.evidence
  TIME: 8 minutes
  ================================================================================
  SCORING SUMMARY
  ================================================================================
  Total Tasks: 12  |  Points per task: 3  |  Total: 36 points
  Passing Score: 25 points (67%)  |  Total Time: 120 minutes
  When done, run: bash /home/vagrant/validate.sh
  ================================================================================
  TICKET

            cat << 'VERIFY' > /tmp/verify-017.sh
  #!/bin/bash
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; RESET='\e[0m'
  PASS="caleston123"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  FAIL=0
  echo -e "\${CYAN}╔════════════════════════════════════════════════════════════════╗\${RESET}"
  echo -e "\${CYAN}║          VERIFYING SCENARIO MOCK-017 (AlmaLinux 9)             ║\${RESET}"
  echo -e "\${CYAN}╚════════════════════════════════════════════════════════════════╝\${RESET}"

  echo -e "\${YELLOW}[1/3] node02: Extra disk and basic packages exist\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "lsblk | grep -q vdb && rpm -q nginx podman sssd" >/dev/null 2>&1; then
    echo -e "      \${GREEN}✓ OK\${RESET}"
  else
    echo -e "      \${RED}✗ FAILED\${RESET}"; FAIL=1
  fi

  echo -e "\${YELLOW}[2/3] node02: SELinux is Enforcing\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "getenforce | grep -q Enforcing" >/dev/null 2>&1; then
    echo -e "      \${GREEN}✓ OK\${RESET}"
  else
    echo -e "      \${RED}✗ FAILED\${RESET}"; FAIL=1
  fi

  echo -e "\${YELLOW}[3/3] node02: User bob exists and has sudo\${RESET}"
  if sshpass -p \$PASS ssh \$SSH_OPTS bob@node02 "sudo -n true" >/dev/null 2>&1; then
    echo -e "      \${GREEN}✓ OK\${RESET}"
  else
    echo -e "      \${RED}✗ FAILED\${RESET}"; FAIL=1
  fi

  echo ""
  if [ \$FAIL -eq 0 ]; then
    echo -e "\${GREEN}✅ SCENARIO READY — Press ENTER to see the ticket\${RESET}"
  else
    echo -e "\${RED}⚠️  SOME CHECKS FAILED\${RESET}"
  fi
  read -r
  cat /home/vagrant/TICKET_MOCK-017.txt
  VERIFY
            chmod +x /tmp/verify-017.sh
            sed -i '/verify-017/d' /home/vagrant/.bashrc 2>/dev/null || true
            echo 'bash /tmp/verify-017.sh' >> /home/vagrant/.bashrc

            cat << 'VALIDATOR' > /home/vagrant/validate.sh
  #!/bin/bash
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  NODE="bob@node02"
  RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; RESET='\033[0m'; BOLD='\033[1m'
  TOTAL=0; MAX=36; PASS_COUNT=0; FAIL_COUNT=0

  run_remote() { sshpass -p "\$PASS" ssh \$SSH_OPTS "\$NODE" "\$1" 2>/dev/null; }

  print_res() {
    local n=\$1; local name=\$2; local pts=\$3; local pass=\$4; local desc=\$5; local out=\$6
    echo -e "\n\${CYAN}┌─ TASK \$n: \$name (\$pts pts) ─\${RESET}"
    echo -e "\${YELLOW}   \$desc\${RESET}"
    if [ "\$pass" -eq 1 ]; then
      echo -e "   \${GREEN}✅ +\$pts pts\${RESET}"
      TOTAL=\$((TOTAL + pts)); PASS_COUNT=\$((PASS_COUNT + 1))
    else
      echo -e "   \${RED}❌ +0 pts\${RESET}"
      echo -e "   \${YELLOW}   Evidence obtained:\${RESET}"
      echo "\$out" | head -n 3 | sed 's/^/   /'
      FAIL_COUNT=\$((FAIL_COUNT + 1))
    fi
  }

  echo -e "\${MAGENTA}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║      🎯 VALIDATOR LFCS — MOCK #017 (AlmaLinux 9)            ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "\${RESET}"

  # 1. GRUB
  out=\$(run_remote "cat /tmp/task_01.evidence 2>/dev/null")
  if echo "\$out" | grep -q "console=ttyS0"; then ok=1; else ok=0; fi
  print_res 1 "grub params" 3 \$ok "Default kernel includes console=ttyS0" "\$out"

  # 2. SSSD
  out=\$(run_remote "cat /tmp/task_02.evidence 2>/dev/null")
  if echo "\$out" | grep -q "sssd" && echo "\$out" | grep -q "enabled"; then ok=1; else ok=0; fi
  print_res 2 "sssd authselect" 3 \$ok "Authselect sssd profile and service enabled" "\$out"

  # 3. QUOTAS
  out=\$(run_remote "cat /tmp/task_03.evidence 2>/dev/null")
  if echo "\$out" | grep -q "bob" && echo "\$out" | grep -E -q "102400|100M|100.0"; then ok=1; else ok=0; fi
  print_res 3 "disk quotas" 3 \$ok "User bob has 100M soft limit on /mnt/quota" "\$out"

  # 4. NGINX
  out=\$(run_remote "cat /tmp/task_04.evidence 2>/dev/null")
  if echo "\$out" | grep -q "location /app" && echo "\$out" | grep -q "proxy_pass.*127.0.0.1:5000"; then ok=1; else ok=0; fi
  print_res 4 "nginx proxy" 3 \$ok "Nginx proxies /app to 127.0.0.1:5000" "\$out"

  # 5. SUID
  out=\$(run_remote "cat /tmp/task_05.evidence 2>/dev/null")
  if echo "\$out" | grep -q "/usr/bin"; then ok=1; else ok=0; fi
  print_res 5 "suid audit" 3 \$ok "SUID files in /usr/bin listed" "\$out"

  # 6. SELINUX
  out=\$(run_remote "cat /tmp/task_06.evidence 2>/dev/null")
  if echo "\$out" | grep -q "on"; then ok=1; else ok=0; fi
  print_res 6 "selinux bool" 3 \$ok "httpd_can_network_connect is ON" "\$out"

  # 7. ROUTING
  out=\$(run_remote "cat /tmp/task_07.evidence 2>/dev/null")
  if echo "\$out" | grep -q "192.168.100.0/24" && echo "\$out" | grep -q "192.168.122.1"; then ok=1; else ok=0; fi
  print_res 7 "static route" 3 \$ok "Persistent route to 192.168.100.0/24" "\$out"

  # 8. CRON
  out=\$(run_remote "cat /tmp/task_08.evidence 2>/dev/null")
  if echo "\$out" | grep -q "*/15" && echo "\$out" | grep -q "cleanup"; then ok=1; else ok=0; fi
  print_res 8 "system cron" 3 \$ok "Cron job runs every 15 mins" "\$out"

  # 9. PODMAN
  out=\$(run_remote "cat /tmp/task_09.evidence 2>/dev/null")
  if echo "\$out" | grep -q "app_logger" && echo "\$out" | grep -q "/var/log/app_data"; then ok=1; else ok=0; fi
  print_res 9 "podman volume" 3 \$ok "Container app_logger with correct volume" "\$out"

  # 10. ENV VAR
  out=\$(run_remote "cat /tmp/task_10.evidence 2>/dev/null")
  if echo "\$out" | grep -q "APP_STAGE=prod"; then ok=1; else ok=0; fi
  print_res 10 "env variable" 3 \$ok "APP_STAGE=prod exported globally" "\$out"

  # 11. LOGROTATE
  out=\$(run_remote "cat /tmp/task_11.evidence 2>/dev/null")
  if echo "\$out" | grep -q "custom_app.log" && echo "\$out" | grep -q "daily" && echo "\$out" | grep -q "rotate 7"; then ok=1; else ok=0; fi
  print_res 11 "logrotate" 3 \$ok "Logrotate configured for custom_app.log" "\$out"

  # 12. TAR
  out=\$(run_remote "cat /tmp/task_12.evidence 2>/dev/null")
  if echo "\$out" | grep -E -q "^[1-9][0-9]*\$"; then ok=1; else ok=0; fi
  print_res 12 "tar archive" 3 \$ok "ssh_backup.tar.gz contains files" "\$out"

  PERCENT=\$((TOTAL * 100 / MAX))
  echo -e "\n\${MAGENTA}╔══════════════════════════════════════════════════════════════╗\${RESET}"
  echo -e "\${MAGENTA}║                     📊 FINAL RESULT                          ║\${RESET}"
  echo -e "\${MAGENTA}╚══════════════════════════════════════════════════════════════╝\${RESET}"
  echo -e "\${BOLD}Score:\${RESET}         \${CYAN}\$TOTAL / \$MAX points (\${PERCENT}%)\${RESET}"
  if [ \$PERCENT -ge 67 ]; then
    echo -e "\n\${GREEN}\${BOLD}🎉 PASSED! CONGRATULATIONS! 🎉\${RESET}"
  else
    echo -e "\n\${RED}\${BOLD}❌ NOT PASSED — KEEP GOING! 💪\${RESET}"
  fi
  VALIDATOR
            chmod +x /home/vagrant/validate.sh
            echo "✅ Ticket + Verification + Validator created."
            echo "🚀 vagrant ssh node01 -> automatic verification"
            echo "📝 When done: bash /home/vagrant/validate.sh"
          SHELL
        end
      end
    end
  end
---
[[Laboratorios del LFCS]]

---


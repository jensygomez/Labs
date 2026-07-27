---
Titulo: SIMULACRO LFCS 014 — "Advanced Operations and Recovery "
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
      { name: "node02", ip: "192.168.122.12", extra_disks: ['1G', '1G'] }
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
          
          export DEBIAN_FRONTEND=noninteractive
          apt-get update -qq
          apt-get install -y -qq sshpass curl acl
        SHELL

        # ── NODE02: SERVER WITH 12 INCIDENTS ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🖥️ Configuring node02 with 12 incidents..."
            export DEBIAN_FRONTEND=noninteractive
            
            # Install required packages for the tasks
            apt-get install -y -qq btrfs-progs xfsprogs nftables podman mdadm quota
            
            # Create mount points and directories
            mkdir -p /mnt/btrfs /mnt/xfs /opt/app /mnt/app-bind
            
            # ── TASK 9 PREREQ: Prepare loop devices for RAID 0 ──
            fallocate -l 100M /raid1.img
            fallocate -l 100M /raid2.img
            losetup /dev/loop10 /raid1.img
            losetup /dev/loop11 /raid2.img
            
            # Ensure loop devices persist across reboot for the candidate
            cat << 'EOF' > /etc/rc.local
  #!/bin/bash
  losetup /dev/loop10 /raid1.img 2>/dev/null
  losetup /dev/loop11 /raid2.img 2>/dev/null
  exit 0
  EOF
            chmod +x /etc/rc.local

            # ── TASK 6 PREREQ: Ensure pcspkr is loaded or available to blacklist ──
            modprobe pcspkr 2>/dev/null || true

            # ── TASK 7 PREREQ: Ensure ssh service is active ──
            systemctl enable ssh 2>/dev/null
            systemctl start ssh 2>/dev/null

            echo "✅ node02 configured with 12 incidents"
          SHELL
        end

        # ── NODE01: TICKET + VERIFICATION + VALIDATOR (Direct Live Check) ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generating Ticket, verification, and validator on node01..."
            
            # ═══════════════════════════════════════════════════════
            # TICKET (English)
            # ═══════════════════════════════════════════════════════
            cat << 'TICKET' > /home/vagrant/TICKET_MOCK-014.txt
  ================================================================================
  TICKET MOCK-014   │  Severity: MEDIUM  │  Environment: PRODUCTION
  🔐 MOCK-014 — Advanced Operations and Recovery v2 (12 Tasks)
  Module: LFCS Complete  │  Difficulty: 3/10  │  Level: L2
  Control Station:    node01  (Administrator — bob)
  Server Node:        node02  (Ubuntu 22.04)
  Cluster Password:   caleston123

  This mock covers advanced storage, network tuning, and security hardening 
  using alternative tools (Btrfs, Nftables, Podman, etc.). 
  Manage your time: ~8–10 minutes per task. If stuck, move on.
  ================================================================================
  TASK 1 — Networking: Create Network Bridge (3 points)
  ================================================================================
  Create a network bridge interface named `br0` on node02. 
  Assign it the static IP address `10.0.0.1/24`. Ensure the interface is UP.
  CRITERIA:
  [ ] Interface br0 exists and is UP                                        --> 50%
  [ ] IP address 10.0.0.1/24 is assigned                                    --> 50%
  TIME: 10 minutes
  ================================================================================
  TASK 2 — Storage: Btrfs Subvolume (3 points)
  ================================================================================
  Format the disk `/dev/vdb` as `btrfs` and mount it persistently on `/mnt/btrfs`.
  Create a btrfs subvolume named `@data` inside it.
  CRITERIA:
  [ ] /dev/vdb is formatted as btrfs and mounted on /mnt/btrfs              --> 50%
  [ ] Subvolume @data exists inside /mnt/btrfs                              --> 50%
  TIME: 10 minutes
  ================================================================================
  TASK 3 — Storage: XFS Project Quota (3 points)
  ================================================================================
  Format the disk `/dev/vdc` as `xfs` and mount it persistently on `/mnt/xfs` 
  with project quotas enabled (`prjquota` mount option).
  CRITERIA:
  [ ] /dev/vdc is formatted as xfs and mounted on /mnt/xfs                  --> 50%
  [ ] Mount options include prjquota                                        --> 50%
  TIME: 10 minutes
  ================================================================================
  TASK 4 — Security: Nftables Firewall (3 points)
  ================================================================================
  Install and enable `nftables`. Create a rule in the `inet` family, `filter` 
  table, `input` chain to explicitly `drop` incoming TCP traffic on port `8080`.
  CRITERIA:
  [ ] nftables service is enabled and running                               --> 30%
  [ ] Rule exists to drop TCP traffic on port 8080                          --> 70%
  TIME: 12 minutes
  ================================================================================
  TASK 5 — Security: SSH Banner (3 points)
  ================================================================================
  Configure the SSH daemon to display the file `/etc/ssh/banner` before user login.
  Create the banner file with the text "AUTHORIZED ACCESS ONLY".
  CRITERIA:
  [ ] /etc/ssh/banner exists and contains the correct text                  --> 40%
  [ ] sshd_config is configured to use /etc/ssh/banner                      --> 60%
  TIME: 8 minutes
  ================================================================================
  TASK 6 — Operations: Blacklist Kernel Module (3 points)
  ================================================================================
  Prevent the `pcspkr` (PC speaker) kernel module from loading automatically 
  by blacklisting it in the appropriate modprobe configuration directory.
  CRITERIA:
  [ ] Configuration file exists in /etc/modprobe.d/                         --> 40%
  [ ] Contains the blacklist directive for pcspkr                           --> 60%
  TIME: 8 minutes
  ================================================================================
  TASK 7 — Operations: Systemd Drop-in Override (3 points)
  ================================================================================
  Create a systemd drop-in override for the `ssh.service` to change its 
  restart behavior. Set `Restart=on-failure` in the `[Service]` section.
  CRITERIA:
  [ ] Drop-in override directory/file exists for ssh.service                --> 40%
  [ ] Contains Restart=on-failure in the [Service] section                  --> 60%
  TIME: 10 minutes
  ================================================================================
  TASK 8 — Operations: Sysctl Kernel Parameter (3 points)
  ================================================================================
  Configure the kernel parameter `vm.dirty_ratio` to `20` persistently so it 
  survives reboots. Apply it to the current running system.
  CRITERIA:
  [ ] Configuration file exists in /etc/sysctl.d/ or /etc/sysctl.conf       --> 40%
  [ ] Current running system reflects vm.dirty_ratio = 20                   --> 60%
  TIME: 8 minutes
  ================================================================================
  TASK 9 — Storage: RAID 0 Striping (3 points)
  ================================================================================
  Create a RAID 0 (striped) array named `/dev/md0` using the loop devices 
  `/dev/loop10` and `/dev/loop11`. Format it as `ext4` and mount it on `/mnt/raid0`.
  CRITERIA:
  [ ] /dev/md0 exists and is configured as RAID 0 (stripe)                  --> 50%
  [ ] Formatted as ext4 and mounted on /mnt/raid0                           --> 50%
  TIME: 12 minutes
  ================================================================================
  TASK 10 — Operations: Podman Registry (3 points)
  ================================================================================
  Install `podman`. Configure the default unqualified search registries in 
  `/etc/containers/registries.conf` to include `docker.io`.
  CRITERIA:
  [ ] podman is installed                                                   --> 30%
  [ ] /etc/containers/registries.conf includes docker.io                    --> 70%
  TIME: 10 minutes
  ================================================================================
  TASK 11 — Storage: Bind Mount (3 points)
  ================================================================================
  Create a persistent bind mount in `/etc/fstab` that maps the directory 
  `/opt/app` to `/mnt/app-bind`. Ensure it is mounted.
  CRITERIA:
  [ ] /etc/fstab contains the bind mount entry                              --> 50%
  [ ] /mnt/app-bind is currently mounted and accessible                     --> 50%
  TIME: 8 minutes
  ================================================================================
  TASK 12 — Operations: Modprobe Options (3 points)
  ================================================================================
  Configure the `loop` kernel module to allow a maximum of `16` loop devices 
  by setting the option `max_loop=16` in the appropriate modprobe configuration 
  file.
  CRITERIA:
  [ ] Configuration file exists in /etc/modprobe.d/                         --> 40%
  [ ] Contains options loop max_loop=16                                     --> 60%
  TIME: 8 minutes
  ================================================================================
  SCORING SUMMARY
  ================================================================================
  Task 1:  3 pts (Network Bridge)     Task 7:  3 pts (Systemd Drop-in)
  Task 2:  3 pts (Btrfs Subvolume)    Task 8:  3 pts (Sysctl Parameter)
  Task 3:  3 pts (XFS Project Quota)  Task 9:  3 pts (RAID 0 Striping)
  Task 4:  3 pts (Nftables Firewall)  Task 10: 3 pts (Podman Registry)
  Task 5:  3 pts (SSH Banner)         Task 11: 3 pts (Bind Mount)
  Task 6:  3 pts (Blacklist Module)   Task 12: 3 pts (Modprobe Options)
  TOTAL: 36 points
  PASSING (67%): 25 points
  TOTAL TIME: 120 minutes

  When done, run: sudo bash /home/vagrant/validate.sh
  ================================================================================
  TICKET

            # ═══════════════════════════════════════════════════════
            # INITIAL VERIFICATION SCRIPT (verify-014.sh)
            # ═══════════════════════════════════════════════════════
            cat << 'VERIFY' > /tmp/verify-014.sh
  #!/bin/bash
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; RESET='\e[0m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"; PASS="caleston123"; FAIL=0

  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║          VERIFYING SCENARIO MOCK-014                           ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "${YELLOW}[1/4] node02: Extra disks /dev/vdb and /dev/vdc exist${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "lsblk | grep -q vdb && lsblk | grep -q vdc" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[2/4] node02: Loop devices for RAID0 are ready${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "losetup -a | grep -q loop10 && losetup -a | grep -q loop11" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[3/4] node02: Required packages installed${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "dpkg -l btrfs-progs nftables podman mdadm 2>/dev/null | grep -c ^ii | grep -q 4" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FAILED${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[4/4] node02: Directories created${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "[ -d /mnt/btrfs ] && [ -d /mnt/xfs ] && [ -d /opt/app ]" 2>/dev/null; then
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
  cat /home/vagrant/TICKET_MOCK-014.txt
  VERIFY
            chmod +x /tmp/verify-014.sh
            sed -i '/verify-014/d' /home/vagrant/.bashrc 2>/dev/null || true
            echo 'bash /tmp/verify-014.sh' >> /home/vagrant/.bashrc

            # ═══════════════════════════════════════════════════════
            # VALIDATOR (validate.sh) — Direct Live Check
            # ═══════════════════════════════════════════════════════
            cat << 'VALIDATOR' > /home/vagrant/validate.sh
  #!/bin/bash
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  NODE="bob@node02"

  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  CYAN='\033[0;36m'
  MAGENTA='\033[0;35m'
  RESET='\033[0m'
  BOLD='\033[1m'

  TOTAL=0
  MAX=36
  PASS_COUNT=0
  FAIL_COUNT=0

  run_remote() {
      sshpass -p "$PASS" ssh $SSH_OPTS "$NODE" "$1" 2>/dev/null
  }

  print_res() {
      local n=$1; local name=$2; local pts=$3; local pass=$4; local desc=$5; local out=$6
      echo -e "\n${CYAN}┌─ TASK $n: $name ($pts pts) ─${RESET}"
      echo -e "${YELLOW}   $desc${RESET}"
      if [ "$pass" -eq 1 ]; then
          echo -e "   ${GREEN}✅ +$pts pts${RESET}"
          TOTAL=$((TOTAL + pts))
          PASS_COUNT=$((PASS_COUNT + 1))
      else
          echo -e "   ${RED}❌ +0 pts${RESET}"
          echo -e "   ${YELLOW}   Salida obtenida:${RESET}"
          echo "$out" | head -n 3 | sed 's/^/   /'
          FAIL_COUNT=$((FAIL_COUNT + 1))
      fi
  }

  echo -e "${MAGENTA}"
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║      🎯 VALIDATOR LFCS — MOCK #014 (Direct Live Check)      ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"

  # 1. NETWORK BRIDGE
  out=$(run_remote "ip a show br0")
  if echo "$out" | grep -q "10.0.0.1"; then ok=1; else ok=0; fi
  print_res 1 "network bridge" 3 $ok "Bridge br0 configured with 10.0.0.1/24" "$out"

  # 2. BTRFS SUBVOLUME
  out=$(run_remote "btrfs subvolume list /mnt/btrfs")
  if echo "$out" | grep -q "@data"; then ok=1; else ok=0; fi
  print_res 2 "btrfs subvolume" 3 $ok "Btrfs subvolume @data created" "$out"

  # 3. XFS PROJECT QUOTA
  out=$(run_remote "mount | grep /mnt/xfs")
  if echo "$out" | grep -q "prjquota"; then ok=1; else ok=0; fi
  print_res 3 "xfs project quota" 3 $ok "XFS mounted with prjquota" "$out"

  # 4. NFTABLES FIREWALL
  out=$(run_remote "sudo nft list ruleset")
  if echo "$out" | grep -q "8080" && echo "$out" | grep -q "drop"; then ok=1; else ok=0; fi
  print_res 4 "nftables firewall" 3 $ok "Nftables rule dropping TCP 8080" "$out"

  # 5. SSH BANNER
  out=$(run_remote "grep -i banner /etc/ssh/sshd_config")
  if echo "$out" | grep -q "/etc/ssh/banner"; then ok=1; else ok=0; fi
  print_res 5 "ssh banner" 3 $ok "SSH daemon configured to show banner" "$out"

  # 6. BLACKLIST KERNEL MODULE
  out=$(run_remote "grep -r pcspkr /etc/modprobe.d/")
  if echo "$out" | grep -q "blacklist"; then ok=1; else ok=0; fi
  print_res 6 "blacklist module" 3 $ok "pcspkr module blacklisted" "$out"

  # 7. SYSTEMD DROP-IN OVERRIDE
  out=$(run_remote "sudo systemctl daemon-reload && sudo systemctl cat ssh.service")
  if echo "$out" | grep -q "Restart=on-failure"; then ok=1; else ok=0; fi
  print_res 7 "systemd drop-in" 3 $ok "SSH service override Restart=on-failure" "$out"

  # 8. SYSCTL KERNEL PARAMETER
  out=$(run_remote "sysctl vm.dirty_ratio; grep -r 'vm.dirty_ratio' /etc/sysctl.d/ /etc/sysctl.conf 2>/dev/null")
  if echo "$out" | grep -q "20" && echo "$out" | grep -q "vm.dirty_ratio"; then ok=1; else ok=0; fi
  print_res 8 "sysctl parameter" 3 $ok "vm.dirty_ratio set to 20 persistently" "$out"

  # 9. RAID 0 STRIPING
  out=$(run_remote "sudo mdadm --detail /dev/md0")
  if echo "$out" | grep -q "raid0"; then ok=1; else ok=0; fi
  print_res 9 "raid 0 striping" 3 $ok "RAID 0 array /dev/md0 created" "$out"

  # 10. PODMAN REGISTRY
  out=$(run_remote "cat /etc/containers/registries.conf")
  if echo "$out" | grep -q "docker.io"; then ok=1; else ok=0; fi
  print_res 10 "podman registry" 3 $ok "Podman registry configured with docker.io" "$out"

  # 11. BIND MOUNT
  out=$(run_remote "grep '/mnt/app-bind' /etc/fstab && findmnt /mnt/app-bind")
  if echo "$out" | grep -q "bind"; then ok=1; else ok=0; fi
  print_res 11 "bind mount" 3 $ok "Bind mount /opt/app to /mnt/app-bind" "$out"

  # 12. MODPROBE OPTIONS (Revisión robusta)
  out=$(run_remote "sudo grep -rnE 'options[[:space:]]+loop[[:space:]]+.*max_loop[[:space:]]*=[[:space:]]*16' /etc/modprobe.d/ 2>/dev/null || cat /sys/module/loop/parameters/max_loop 2>/dev/null")
  if echo "$out" | grep -qE "max_loop|16"; then ok=1; else ok=0; fi
  print_res 12 "modprobe options" 3 $ok "Loop module max_loop set to 16" "$out"

  PERCENT=$((TOTAL * 100 / MAX))

  echo -e "\n${MAGENTA}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${MAGENTA}║                     📊 FINAL RESULT                          ║${RESET}"
  echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo -e "${BOLD}Score:${RESET}         ${CYAN}$TOTAL / $MAX points (${PERCENT}%)${RESET}\n"

  if [ $PERCENT -ge 67 ]; then
    echo -e "${GREEN}${BOLD}🎉 PASSED! CONGRATULATIONS! 🎉${RESET}\n"
  else
    echo -e "${RED}${BOLD}❌ NOT PASSED — KEEP GOING! 💪${RESET}\n"
  fi
  VALIDATOR
            chmod +x /home/vagrant/validate.sh

            echo "✅ Ticket + Verification + Validator created."
            echo "🚀 vagrant ssh node01 → automatic verification"
            echo "📝 When done: sudo bash /home/vagrant/validate.sh"
          SHELL
        end
      end
    end
  end
---
[[Laboratorios del LFCS]]

---


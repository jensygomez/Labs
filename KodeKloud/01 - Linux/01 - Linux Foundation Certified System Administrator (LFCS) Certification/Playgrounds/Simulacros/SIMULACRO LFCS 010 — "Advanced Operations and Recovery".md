---
Titulo: SIMULACRO LFCS 010 — "Advanced Operations and Recovery"
Severidad: MEDIA
Ambiente: Produccion
Modulo: LFCS Complete
Dificultad: 3/10
Nivel: L2
Fecha de Inicio: 2026-07-22
Script Vagrant: |-
  # -- mode: ruby --

  # vi: set ft=ruby :

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/ubuntu2204"
    
    nodes = [
      { name: "node01", ip: "192.168.122.11", extra_disks: [] },
      { name: "node02", ip: "192.168.122.12", extra_disks: ['1G', '1G'] },  # for LVM and RAID
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
          apt-get install -y -qq sshpass curl acl lvm2 ufw zip tree ntp nfs-kernel-server mdadm quota
        SHELL
        
        # ── NODE02: SERVER WITH 12 INCIDENTS ──
        if node[:name] == "node02"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🖥️ Configuring node02 with 12 incidents..."
            
            export DEBIAN_FRONTEND=noninteractive
            apt-get install -y -qq nginx vim tree
            
            # ── TASK 1: no bonding config yet ──
            rm -f /etc/netplan/99-bond.yaml 2>/dev/null || true
            
            # ── TASK 2: create a VG and LV for snapshot later ──
            # Use /dev/vdb (1G) as PV, VG named snapvg, LV named origin_lv (200M)
            pvcreate /dev/vdb 2>/dev/null || true
            vgcreate snapvg /dev/vdb 2>/dev/null || true
            lvcreate -L 200M -n origin_lv snapvg 2>/dev/null || true
            mkfs.ext4 /dev/snapvg/origin_lv 2>/dev/null || true
            mkdir -p /mnt/origin
            mount /dev/snapvg/origin_lv /mnt/origin 2>/dev/null || true
            echo "Snapshot test data" > /mnt/origin/test.txt
            # Snapshot does NOT exist yet
            lvremove -f snapvg/snapshot_lv 2>/dev/null || true
            
            # ── TASK 3: create a small filesystem for quotas ──
            # Use /dev/vdc (1G) partitioned? Actually we have two disks: vdb and vdc.
            # We'll use a loop file for quotas to avoid messing with vdc.
            dd if=/dev/zero of=/var/tmp/quotafile.img bs=1M count=100 2>/dev/null
            mkfs.ext4 /var/tmp/quotafile.img 2>/dev/null || true
            mkdir -p /mnt/quota
            mount -o loop,usrquota /var/tmp/quotafile.img /mnt/quota 2>/dev/null || true
            quotaon -u /mnt/quota 2>/dev/null || true
            # We will remove quotas to force student to enable them
            quotaoff /mnt/quota 2>/dev/null || true
            # Remove mount fstab entry if any
            sed -i '/quotafile/d' /etc/fstab 2>/dev/null || true
            
            # ── TASK 4: iptables rules (none yet) ──
            iptables -D INPUT -s 1.2.3.4 -p tcp --dport 22 -j DROP 2>/dev/null || true
            
            # ── TASK 5: SSH keys (no authorized_keys for bob on node03) ──
            ssh bob@node03 "rm -f ~/.ssh/authorized_keys" 2>/dev/null || true
            
            # ── TASK 6: dummy module not loaded persistently ──
            sed -i '/^dummy/d' /etc/modules 2>/dev/null || true
            rmmod dummy 2>/dev/null || true
            
            # ── TASK 7: default target may be graphical.target; we'll set to multi-user to force change ──
            # Actually Ubuntu default is multi-user.target, but we can set to graphical if not installed?
            # We'll leave as is, student must change to multi-user.target.
            # If already multi-user, we change to graphical temporarily?
            if [ "$(systemctl get-default)" = "multi-user.target" ]; then
              systemctl set-default graphical.target 2>/dev/null || true
            fi
            
            # ── TASK 8: GRUB command line (no extra) ──
            sed -i 's/console=ttyS0//g' /etc/default/grub 2>/dev/null || true
            update-grub 2>/dev/null || true
            
            # ── TASK 9: RAID array not present ──
            mdadm --stop /dev/md0 2>/dev/null || true
            mdadm --zero-superblock /dev/loop0 2>/dev/null || true
            mdadm --zero-superblock /dev/loop1 2>/dev/null || true
            # create loop devices for RAID
            dd if=/dev/zero of=/var/tmp/raid1.img bs=1M count=100 2>/dev/null
            dd if=/dev/zero of=/var/tmp/raid2.img bs=1M count=100 2>/dev/null
            losetup /dev/loop0 /var/tmp/raid1.img 2>/dev/null || true
            losetup /dev/loop1 /var/tmp/raid2.img 2>/dev/null || true
            # ensure no md array
            mdadm --remove /dev/md0 2>/dev/null || true
            
            # ── TASK 10: no Docker repo yet ──
            rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null || true
            
            # ── TASK 11: NFS export already from /opt/shared (created previously) ──
            # We'll mount it locally on /mnt/nfs-local (not yet)
            mkdir -p /opt/shared
            chmod 777 /opt/shared
            echo "Shared NFS data" > /opt/shared/welcome.txt
            grep -q "/opt/shared" /etc/exports || echo "/opt/shared *(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
            systemctl enable --now nfs-kernel-server 2>/dev/null || service nfs-kernel-server restart
            exportfs -ra
            # Student's task: mount it as NFS client on /mnt/nfs-local (not yet)
            mkdir -p /mnt/nfs-local
            umount /mnt/nfs-local 2>/dev/null || true
            
            # ── TASK 12: initramfs already up-to-date, but we can add a dummy hook to force update ──
            rm -f /etc/initramfs-tools/conf.d/dummy 2>/dev/null || true
            
            systemctl enable nginx
            systemctl start nginx
            
            echo "✅ node02 configured with 12 incidents"
          SHELL
        end
        
        # ── NODE03: VAULT ──
        if node[:name] == "node03"
          node_config.vm.provision "shell", privileged: true, inline: <<-SHELL
            echo "🔒 Preparing vault..."
            mkdir -p /opt/ops-compliance/mock-exam-010
            chown -R bob:bob /opt/ops-compliance
            chmod -R 755 /opt/ops-compliance
            # also prepare for SSH key: create .ssh directory for bob
            mkdir -p /home/bob/.ssh
            chown bob:bob /home/bob/.ssh
            chmod 700 /home/bob/.ssh
            echo "✅ Vault ready at /opt/ops-compliance/mock-exam-010/"
          SHELL
        end
        
        # ── NODE01: TICKET + VERIFICATION + VALIDATOR (evidence‑based) ──
        if node[:name] == "node01"
          node_config.vm.provision "shell", privileged: false, inline: <<-SHELL
            echo "🎫 Generating Ticket, verification, validator, and evidence script on node01..."
            
            # ═══════════════════════════════════════════════════════
            # TICKET (English)
            # ═══════════════════════════════════════════════════════
            cat << 'TICKET' > /home/vagrant/TICKET_MOCK-010.txt
  ================================================================================
  TICKET MOCK-010   │  Severity: MEDIUM  │  Environment: PRODUCTION
  🔐 MOCK-010 — Advanced Operations and Recovery (12 Tasks)
  Module: LFCS Complete  │  Difficulty: 3/10  │  Level: L2
  Control Station:    node01  (Administrator — bob)
  Server Node:        node02  (Ubuntu 22.04)
  Vault Destination:  node03  (/opt/ops-compliance/mock-exam-010/)
  Cluster Password:   caleston123

  This server (node02) requires 12 system administration tasks covering advanced
  topics not yet addressed. Manage your time: ~8–10 minutes per task.
  If stuck, move to the next one.

  ================================================================================
  TASK 1 — Network Bonding: Create a Bond Interface (3 points)
  ================================================================================
  Create a bond0 interface with two dummy slaves in active‑backup mode (mode 1).

  On node02:
  1. Load the bonding and dummy kernel modules (if not already).
  2. Create two dummy interfaces: dummy0 and dummy1.
  3. Create a bond0 interface with IP address 10.0.0.100/24.
  4. Add dummy0 and dummy1 as slaves.
  5. Make it persistent using a netplan configuration file (/etc/netplan/99-bond.yaml).
     (Use the `networkd` renderer; set the bond parameters.)
  6. Apply the netplan.

  CRITERIA:
    [ ] bond0 interface exists (ip link show bond0)                        --> 30%
    [ ] bond0 has IP 10.0.0.100/24                                         --> 30%
    [ ] dummy0 and dummy1 are slaves of bond0                              --> 20%
    [ ] Netplan file exists with correct config                            --> 20%

  TIME: 15 minutes

  ================================================================================
  TASK 2 — LVM Snapshots: Create a Snapshot (3 points)
  ================================================================================
  Create a snapshot of the existing logical volume /dev/snapvg/origin_lv.

  On node02:
  1. The VG 'snapvg' and LV 'origin_lv' (200M, ext4) already exist and are mounted at /mnt/origin.
  2. Create a snapshot LV named 'snapshot_lv' with size 50M (or use -L 50M).
  3. Mount the snapshot to /mnt/snapshot (create the directory).
  4. Verify the snapshot contains the test data (test.txt).

  CRITERIA:
    [ ] Snapshot LV exists (lvs | grep snapshot_lv)                       --> 40%
    [ ] Snapshot is mounted at /mnt/snapshot                               --> 30%
    [ ] /mnt/snapshot/test.txt exists with correct content                 --> 30%

  TIME: 10 minutes

  ================================================================================
  TASK 3 — Disk Quotas: Enable User Quotas (3 points)
  ================================================================================
  Enable user quotas on the filesystem mounted at /mnt/quota.

  On node02:
  1. The loop device /var/tmp/quotafile.img is already mounted at /mnt/quota,
     but quotas are disabled.
  2. Enable quotas on that filesystem (use quotaon).
  3. Set a soft limit of 10M and hard limit of 15M for user bob on that filesystem
     (using edquota or setquota).
  4. Verify the quota is active (quota -u bob).

  CRITERIA:
    [ ] quotaon is active for /mnt/quota (repquota /mnt/quota shows something) --> 40%
    [ ] Bob has soft/hard limits set (quota -u bob shows limits)             --> 40%
    [ ] The limits are correctly set (10M / 15M)                            --> 20%

  TIME: 12 minutes

  ================================================================================
  TASK 4 — iptables: Block SSH from Suspicious IP (3 points)
  ================================================================================
  Add a firewall rule to drop all incoming SSH traffic from IP 1.2.3.4.

  On node02:
  1. Use iptables to add a rule in the INPUT chain.
  2. Rule: -A INPUT -s 1.2.3.4 -p tcp --dport 22 -j DROP.
  3. Make it persistent using iptables-persistent (or save rules).
     (Hint: install iptables-persistent if needed; Ubuntu may have netfilter-persistent.)
  4. Verify the rule is present (iptables -L INPUT -n).

  CRITERIA:
    [ ] iptables rule exists (iptables -L INPUT -n | grep '1.2.3.4')        --> 60%
    [ ] Rule is persistent across reboots (check saved file)                --> 40%

  TIME: 10 minutes

  ================================================================================
  TASK 5 — SSH Key Authentication: Passwordless SSH to node03 (3 points)
  ================================================================================
  Set up passwordless SSH from bob@node02 to bob@node03 using key authentication.

  On node02 (as bob):
  1. Generate an RSA key pair (ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa).
  2. Copy the public key to node03 (ssh-copy-id bob@node03).
  3. Test that you can SSH to node03 without password.

  CRITERIA:
    [ ] ~/.ssh/id_rsa (private key) exists and has correct permissions (600) --> 30%
    [ ] ~/.ssh/id_rsa.pub exists                                             --> 20%
    [ ] ssh bob@node03 'echo ok' succeeds without password                   --> 50%

  TIME: 10 minutes

  ================================================================================
  TASK 6 — Kernel Modules: Load dummy Module Persistently (3 points)
  ================================================================================
  Configure the system to load the 'dummy' kernel module at boot.

  On node02:
  1. Add 'dummy' to /etc/modules.
  2. Load it immediately (modprobe dummy).
  3. Verify the module is loaded (lsmod | grep dummy).

  CRITERIA:
    [ ] /etc/modules contains 'dummy'                                         --> 40%
    [ ] Module is loaded (lsmod | grep dummy)                                --> 30%
    [ ] Module will load on boot (check initramfs or modules-load.d)         --> 30%

  TIME: 5 minutes

  ================================================================================
  TASK 7 — Systemd: Change Default Target (3 points)
  ================================================================================
  Change the default systemd target to multi-user.target.

  On node02:
  1. Check the current default target (systemctl get-default).
  2. If not already multi-user.target, change it using systemctl set-default.
  3. Verify the change.

  CRITERIA:
    [ ] Default target is multi-user.target (systemctl get-default)         --> 100%

  TIME: 3 minutes

  ================================================================================
  TASK 8 — Boot Parameters: Add console=ttyS0 (3 points)
  ================================================================================
  Add the kernel parameter 'console=ttyS0' to the GRUB command line persistently.

  On node02:
  1. Edit /etc/default/grub and add 'console=ttyS0' to GRUB_CMDLINE_LINUX_DEFAULT.
  2. Update GRUB (update-grub).
  3. Verify the parameter appears in /boot/grub/grub.cfg.

  CRITERIA:
    [ ] /etc/default/grub contains console=ttyS0                             --> 40%
    [ ] update-grub was run (timestamp of grub.cfg changed)                 --> 30%
    [ ] grub.cfg contains the parameter                                     --> 30%

  TIME: 10 minutes

  ================================================================================
  TASK 9 — RAID 1: Create a Software RAID Array (3 points)
  ================================================================================
  Create a RAID1 array using two loop devices.

  On node02:
  1. The loop devices /dev/loop0 and /dev/loop1 (100M each) are already prepared.
  2. Create a RAID1 array /dev/md0 using mdadm.
  3. Format /dev/md0 as ext4.
  4. Mount it at /mnt/raid (create the directory).
  5. Persist the array (write mdadm.conf and update initramfs).

  CRITERIA:
    [ ] /dev/md0 exists and is RAID1                                        --> 30%
    [ ] /dev/md0 is formatted as ext4 and mounted at /mnt/raid             --> 30%
    [ ] mdadm.conf contains the array                                       --> 20%
    [ ] Array is persistent (check after reboot simulation)                --> 20%

  TIME: 15 minutes

  ================================================================================
  TASK 10 — Package Management: Add Docker Repository (3 points)
  ================================================================================
  Add the official Docker repository to apt sources.

  On node02:
  1. Add Docker's GPG key and repository (e.g., from docs.docker.com).
     Use the standard command: curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
     Then add: deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
     to /etc/apt/sources.list.d/docker.list.
  2. Run apt update and verify that docker-ce becomes available (apt-cache policy docker-ce).

  CRITERIA:
    [ ] /etc/apt/sources.list.d/docker.list exists with correct URL        --> 40%
    [ ] GPG key is installed                                                --> 20%
    [ ] apt update succeeds and docker-ce appears (apt-cache policy)       --> 40%

  TIME: 10 minutes

  ================================================================================
  TASK 11 — NFS Client: Mount Local NFS Export (3 points)
  ================================================================================
  Mount the NFS export from node02 itself (loopback) to /mnt/nfs-local.

  On node02:
  1. The directory /opt/shared is already exported via NFS (from provisioning).
  2. Mount that NFS share (localhost:/opt/shared) to /mnt/nfs-local.
  3. Verify the mount is active (mount | grep nfs).
  4. Optionally add to fstab for persistence (not required for score).

  CRITERIA:
    [ ] NFS mount exists (mount | grep nfs)                                 --> 40%
    [ ] /mnt/nfs-local is mounted and shows the shared content             --> 30%
    [ ] The mount is accessible (ls /mnt/nfs-local)                        --> 30%

  TIME: 8 minutes

  ================================================================================
  TASK 12 — System Recovery: Update initramfs (3 points)
  ================================================================================
  Update the initramfs to include a custom module (dummy) already configured.

  On node02:
  1. Ensure the dummy module is configured to load (from Task 6).
  2. Run update-initramfs -u to rebuild the initramfs.
  3. Verify the update by checking the timestamp of the initramfs image.

  CRITERIA:
    [ ] update-initramfs command was executed (timestamp /boot/initrd.img-*)   --> 40%
    [ ] The initramfs image exists and is newer than /etc/modules             --> 30%
    [ ] The dummy module is included (check with lsinitramfs | grep dummy)  --> 30%

  TIME: 8 minutes

  ================================================================================
  EVIDENCE PIPELINE TO NODE03 (Optional — does not affect score)
  ================================================================================
  To automate evidence collection, run on node01:
    bash /home/vagrant/generate-evidence.sh

  This fetches outputs for all 12 tasks and stores them in:
    node03:/opt/ops-compliance/mock-exam-010/evidence.txt

  It is **not mandatory** but required for validation (validate.sh reads from there).

  ================================================================================
  SCORING SUMMARY
  ================================================================================
  Task 1:  3 pts (Bonding)
  Task 2:  3 pts (LVM Snapshot)
  Task 3:  3 pts (Quotas)
  Task 4:  3 pts (iptables)
  Task 5:  3 pts (SSH Keys)
  Task 6:  3 pts (Kernel Module)
  Task 7:  3 pts (Systemd Target)
  Task 8:  3 pts (GRUB Param)
  Task 9:  3 pts (RAID 1)
  Task 10: 3 pts (Package Repo)
  Task 11: 3 pts (NFS Client)
  Task 12: 3 pts (Initramfs)
  TOTAL: 36 points
  PASSING (67%): 25 points

  TOTAL TIME: 120 minutes

  When done, run: bash /home/vagrant/validate.sh
  ================================================================================
  TICKET

            # ═══════════════════════════════════════════════════════
            # INITIAL VERIFICATION SCRIPT (verify-010.sh)
            # ═══════════════════════════════════════════════════════
            cat << 'VERIFY' > /tmp/verify-010.sh
  #!/bin/bash
  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; RESET='\e[0m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"; PASS="caleston123"; FAIL=0

  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║          VERIFYING SCENARIO MOCK-010                           ║${RESET}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  echo -e "${YELLOW}[1/8] node02: LVM VG and LV exist${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo vgs | grep -q snapvg && sudo lvs | grep -q origin_lv" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[2/8] node02: quota loop filesystem mounted${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "mount | grep -q /mnt/quota" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[3/8] node02: loop devices for RAID exist${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "losetup /dev/loop0 2>/dev/null && losetup /dev/loop1 2>/dev/null" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[4/8] node02: NFS export /opt/shared exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo exportfs -v 2>/dev/null | grep -q /opt/shared" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[5/8] node02: /etc/default/grub exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "[ -f /etc/default/grub ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[6/8] node02: dummy module not loaded${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node02 "lsmod | grep -q dummy" 2>/dev/null; then
    echo -e "      ${RED}✗ dummy already loaded${RESET}"; FAIL=1
  else
    echo -e "      ${GREEN}✓ OK (not loaded)${RESET}"
  fi

  echo -e "${YELLOW}[7/8] node03: .ssh directory exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node03 "[ -d /home/bob/.ssh ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo -e "${YELLOW}[8/8] node03: Vault exists${RESET}"
  if sshpass -p $PASS ssh $SSH_OPTS bob@node03 "[ -d /opt/ops-compliance/mock-exam-010 ]" 2>/dev/null; then
    echo -e "      ${GREEN}✓ OK${RESET}"
  else
    echo -e "      ${RED}✗ FALLÓ${RESET}"; FAIL=1
  fi

  echo ""
  if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ SCENARIO READY — Press ENTER to see the ticket${RESET}"
  else
    echo -e "${RED}⚠️  SOME CHECKS FAILED${RESET}"
  fi
  echo ""
  read -r
  cat /home/vagrant/TICKET_MOCK-010.txt
  VERIFY
            chmod +x /tmp/verify-010.sh
            sed -i '/verify-010/d' /home/vagrant/.bashrc 2>/dev/null || true
            echo 'bash /tmp/verify-010.sh' >> /home/vagrant/.bashrc

            # ═══════════════════════════════════════════════════════
            # EVIDENCE GENERATOR (generate-evidence.sh)
            # ═══════════════════════════════════════════════════════
            #
            # NOTE: This script is the single source of truth for validation.
            # The header lines (--- TASK N: DESCRIPTION ---) MUST match
            # exactly those searched by validate.sh (case, spacing, number).
            #
            cat << 'EVIDENCE' > /home/vagrant/generate-evidence.sh
  #!/bin/bash
  # generate-evidence.sh - Collects output for each task and saves to node03.
  # Header format must be synchronized with validate.sh.

  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  DEST="node03:/opt/ops-compliance/mock-exam-010/evidence.txt"

  echo "🔍 Collecting evidence from node02..."
  {
    echo "=== EVIDENCE FOR MOCK-010 ==="
    echo "Date: $(date)"
    echo ""

    # TASK 1: Bonding
    echo "--- TASK 1: BONDING INTERFACE ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ip link show bond0 2>/dev/null; ip addr show bond0 2>/dev/null; ip link show dummy0 2>/dev/null; cat /etc/netplan/99-bond.yaml 2>/dev/null || echo 'bonding missing'"
    echo ""

    # TASK 2: LVM Snapshot
    echo "--- TASK 2: LVM SNAPSHOT ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo lvs 2>/dev/null | grep snapshot_lv; mount | grep snapshot; cat /mnt/snapshot/test.txt 2>/dev/null || echo 'snapshot missing'"
    echo ""

    # TASK 3: Quotas
    echo "--- TASK 3: DISK QUOTAS ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo quotaon -p /mnt/quota 2>/dev/null; sudo quota -u bob 2>/dev/null || echo 'quotas missing'"
    echo ""

    # TASK 4: iptables
    echo "--- TASK 4: IPTABLES RULE ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo iptables -L INPUT -n 2>/dev/null | grep '1.2.3.4' || echo 'rule missing'"
    echo ""

    # TASK 5: SSH keys
    echo "--- TASK 5: SSH KEY AUTH ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls -l ~/.ssh/id_rsa 2>/dev/null; ssh -o BatchMode=yes -o ConnectTimeout=5 bob@node03 'echo ok' 2>/dev/null || echo 'key auth failed'"
    echo ""

    # TASK 6: Kernel module dummy
    echo "--- TASK 6: DUMMY MODULE ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "grep dummy /etc/modules 2>/dev/null; lsmod | grep dummy || echo 'dummy not loaded'"
    echo ""

    # TASK 7: Systemd default target
    echo "--- TASK 7: DEFAULT TARGET ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "systemctl get-default 2>/dev/null || echo 'target missing'"
    echo ""

    # TASK 8: GRUB parameter
    echo "--- TASK 8: GRUB CMDLINE ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "grep 'console=ttyS0' /etc/default/grub 2>/dev/null; grep 'console=ttyS0' /boot/grub/grub.cfg 2>/dev/null || echo 'grub param missing'"
    echo ""

    # TASK 9: RAID 1
    echo "--- TASK 9: RAID ARRAY ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "sudo mdadm --detail /dev/md0 2>/dev/null || echo 'raid missing'; mount | grep md0; cat /etc/mdadm/mdadm.conf 2>/dev/null | grep md0 || echo 'no mdadm.conf entry'"
    echo ""

    # TASK 10: Docker repo
    echo "--- TASK 10: DOCKER REPO ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "cat /etc/apt/sources.list.d/docker.list 2>/dev/null || echo 'repo missing'; apt-cache policy docker-ce 2>/dev/null | head -n 5 || echo 'docker-ce not found'"
    echo ""

    # TASK 11: NFS mount
    echo "--- TASK 11: NFS CLIENT MOUNT ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "mount | grep nfs | grep /mnt/nfs-local || echo 'nfs mount missing'; ls -l /mnt/nfs-local 2>/dev/null || echo 'not accessible'"
    echo ""

    # TASK 12: Initramfs update
    echo "--- TASK 12: INITRAMFS UPDATE ---"
    sshpass -p $PASS ssh $SSH_OPTS bob@node02 "ls -l /boot/initrd.img-* 2>/dev/null | head -n 1; lsinitramfs /boot/initrd.img-* 2>/dev/null | grep dummy || echo 'dummy not in initramfs'"
    echo ""

    echo "=== END OF EVIDENCE ==="
  } | sshpass -p $PASS ssh $SSH_OPTS bob@node03 "cat > /opt/ops-compliance/mock-exam-010/evidence.txt"

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
            #
            # NOTE: This script fetches evidence.txt ONCE from node03,
            # then validates each task using its dedicated block.
            # Headers must match those in generate-evidence.sh exactly.
            #
            cat << 'VALIDATOR' > /home/vagrant/validate.sh
  #!/bin/bash
  # validate.sh - Validates all tasks by reading evidence.txt from node03.
  # Single fetch, scoped grep per task, graceful failure if evidence missing.

  RED='\e[1;31m'; GREEN='\e[1;32m'; YELLOW='\e[1;33m'; CYAN='\e[1;36m'; MAGENTA='\e[1;35m'; RESET='\e[0m'; BOLD='\e[1m'
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  PASS="caleston123"
  TOTAL=0; MAX=36; PASS_COUNT=0; FAIL_COUNT=0

  # --- Fetch evidence from node03 ---
  EVIDENCE_FILE="/tmp/evidence-$$.txt"
  echo -e "${CYAN}Fetching evidence from node03...${RESET}"
  if ! sshpass -p $PASS scp $SSH_OPTS bob@node03:/opt/ops-compliance/mock-exam-010/evidence.txt "$EVIDENCE_FILE" 2>/dev/null; then
    echo -e "${RED}ERROR: Could not fetch evidence.txt from node03.${RESET}"
    echo -e "${RED}Please run 'bash /home/vagrant/generate-evidence.sh' first.${RESET}"
    exit 1
  fi

  # Helper to extract a task's block (between its header and the next header)
  extract_block() {
    local task_num=$1
    local next_num=$((task_num + 1))
    local header_pattern="--- TASK ${task_num}:"
    local next_header_pattern="--- TASK ${next_num}:"
    # If next_num > 12, use end-of-file
    if [ $next_num -le 12 ]; then
      sed -n "/$header_pattern/,/$next_header_pattern/p" "$EVIDENCE_FILE" | sed '$d'  # remove line with next header
    else
      sed -n "/$header_pattern/,\$p" "$EVIDENCE_FILE"
    fi
  }

  # Check if a block contains a pattern (grep -q)
  block_contains() {
    local block="$1"
    local pattern="$2"
    echo "$block" | grep -q "$pattern"
  }

  # Wrapper for each task validation
  validate_task() {
    local n=$1; local name=$2; local pts=$3; local pattern=$4; local desc=$5
    echo -e "\n${CYAN}┌─ TASK $n: $name ($pts pts) ─${RESET}"
    echo -e "${YELLOW}   $desc${RESET}"
    
    block=$(extract_block $n)
    if [ -z "$block" ]; then
      echo -e "   ${RED}❌ Evidence block for Task $n not found (header missing).${RESET}"
      echo -e "   ${YELLOW}   Run generate-evidence.sh again.${RESET}"
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
  echo "║     🎯 VALIDATOR LFCS — MOCK #010                            ║"
  echo "║        Advanced Operations and Recovery (12 tasks)           ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
  echo -e "${BOLD}Validating using evidence from node03...${RESET}\n"

  # T1: Bonding
  validate_task 1 "Bonding" 3 \
    "bond0.*state UP|bond0.*10\.0\.0\.100|dummy0.*master bond0|dummy1.*master bond0|netplan.*bond0" \
    "bond0 exists with IP 10.0.0.100/24, dummy slaves, netplan config"

  # T2: LVM Snapshot
  validate_task 2 "LVM Snapshot" 3 \
    "snapshot_lv|/mnt/snapshot|test.txt.*Snapshot test data" \
    "Snapshot LV exists, mounted, test.txt present"

  # T3: Quotas
  validate_task 3 "Quotas" 3 \
    "quotaon.*/mnt/quota|quota.*bob.*10M.*15M|soft.*hard.*10.*15" \
    "Quotas enabled, bob has 10M/15M limits"

  # T4: iptables rule
  validate_task 4 "iptables" 3 \
    "1\.2\.3\.4.*dport 22.*DROP|DROP.*1\.2\.3\.4" \
    "iptables rule blocks SSH from 1.2.3.4"

  # T5: SSH key auth
  validate_task 5 "SSH keys" 3 \
    "id_rsa.*600|ssh bob@node03.*ok" \
    "SSH key pair exists, passwordless login works"

  # T6: dummy module
  validate_task 6 "Dummy module" 3 \
    "dummy.*modules|lsmod.*dummy" \
    "dummy module in /etc/modules and loaded"

  # T7: systemd target
  validate_task 7 "Systemd target" 3 \
    "multi-user\.target" \
    "Default target is multi-user.target"

  # T8: GRUB parameter
  validate_task 8 "GRUB param" 3 \
    "console=ttyS0" \
    "console=ttyS0 in /etc/default/grub and grub.cfg"

  # T9: RAID 1
  validate_task 9 "RAID 1" 3 \
    "md0.*active.*raid1|/mnt/raid|mdadm.conf.*md0" \
    "RAID1 /dev/md0, mounted, persistent"

  # T10: Docker repo
  validate_task 10 "Docker repo" 3 \
    "docker\.list|docker-ce.*candidate" \
    "Docker repo added, docker-ce available"

  # T11: NFS mount
  validate_task 11 "NFS client" 3 \
    "nfs.*/mnt/nfs-local|localhost:/opt/shared" \
    "NFS mount to /mnt/nfs-local active"

  # T12: Initramfs update
  validate_task 12 "Initramfs update" 3 \
    "initrd.img.*timestamp|lsinitramfs.*dummy" \
    "initramfs updated, contains dummy module"

  # ── Cleanup ──
  rm -f "$EVIDENCE_FILE"

  # ── Final summary ──
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
            echo "📦 (Optional) Send evidence: bash /home/vagrant/generate-evidence.sh"
          SHELL
        end
      end
    end
  end
---
[[Laboratorios del LFCS]]

---


#!/bin/bash
# inc-009-cross-db-password-mismatch.sh
# Incident: One node in the HA fleet has a stale database credential.
# Its liveness health-check (HTTP) reports healthy, but its heartbeat
# writes to the central database are silently failing authentication.

set -e

echo "======================================================================"
echo "🚀 PREPARING LAB: INC-009 - Cross DB Password Mismatch"
echo "======================================================================"

# ==========================================
# STEP 1: Create 4 containers (server01-04)
# ==========================================
echo ""
echo "📦 Step 1: Creating 4 servers..."
for i in {1..4}; do
    NODE="server0$i"
    if ! lxc info $NODE &>/dev/null; then
        echo "   → Creating $NODE..."
        lxc launch images:almalinux/9 $NODE --profile default
    else
        echo "   → $NODE already exists."
    fi
done

# server04 (storage/DB node) needs privileged mode for full service control
echo "   → Setting server04 as privileged (storage/backend role)..."
lxc config set server04 security.privileged true
lxc restart server04

echo "⏳ Waiting 20s for containers to boot..."
sleep 20

# ==========================================
# STEP 2: Generate inventory.ini (ansible_connection=lxd, no IP detection needed)
# ==========================================
echo ""
echo "🌐 Step 2: Writing inventory.ini (lxd connection plugin, no DHCP IP lookup)..."

cat > inventory.ini << 'EOF'
[storage]
server04

[fleet]
server01
server02
server03

[all_nodes:children]
storage
fleet

[all:vars]
ansible_connection=lxd
ansible_user=root

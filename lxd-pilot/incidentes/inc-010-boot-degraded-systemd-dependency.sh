#!/bin/bash
# inc-010-boot-degraded-systemd-dependency.sh
# Incident: One node in the fleet enters a "degraded" systemd boot state
# after a maintenance reboot because a custom NFS .mount unit is missing
# correct network ordering. The dependent sync service therefore fails to
# start too, but the HTTP liveness check is a completely separate service
# and keeps returning 200 OK.

set -e

echo "======================================================================"
echo "🚀 PREPARING LAB: INC-010 - Boot Degraded Systemd Dependency"
echo "======================================================================"

# ==========================================
# STEP 0: Destroy any pre-existing lab containers (fresh, independent build)
# ==========================================
echo ""
echo "🧹 Step 0: Ensuring a clean slate (destroying any pre-existing server01-04)..."
for i in {1..4}; do
    NODE="server0$i"
    if lxc info $NODE &>/dev/null; then
        echo "   → Deleting existing $NODE..."
        lxc delete $NODE --force
    fi
done

# ==========================================
# STEP 1: Create 4 fresh containers (server01-04)
# ==========================================
echo ""
echo "📦 Step 1: Creating 4 fresh servers from golden image..."
for i in {1..4}; do
    NODE="server0$i"
    echo "   → Creating $NODE..."
    lxc launch images:almalinux/9 $NODE --profile default
done

# server04 (NFS storage node) needs privileged mode for full service control
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
EOF

echo "   ✅ inventory.ini written."

# ==========================================
# STEP 3: Install packages
# ==========================================
echo ""
echo "📦 Step 3: Installing packages..."

echo "   → server04 (storage/NFS): nfs-utils, firewalld..."
lxc exec server04 -- dnf install -y nfs-utils firewalld >/dev/null 2>&1
lxc exec server04 -- systemctl enable --now firewalld >/dev/null 2>&1

for i in {1..3}; do
    NODE="server0$i"
    echo "   → $NODE (fleet): nfs-utils (client), rsync, nginx, curl, firewalld..."
    lxc exec $NODE -- dnf install -y nfs-utils rsync nginx curl firewalld >/dev/null 2>&1
    lxc exec $NODE -- systemctl enable --now nginx firewalld >/dev/null 2>&1
done

# ==========================================
# STEP 4: Configure the real NFS backend on server04
# ==========================================
echo ""
echo "🔧 Step 4: Configuring NFS export on server04 (real backend service)..."

lxc exec server04 -- mkdir -p /exports/central-orders
lxc exec server04 -- chmod 777 /exports/central-orders

lxc exec server04 -- bash -c "echo '/exports/central-orders 10.45.223.0/24(rw,sync,no_subtree_check,no_root_squash)' > /etc/exports"
lxc exec server04 -- systemctl enable --now nfs-server >/dev/null 2>&1
lxc exec server04 -- exportfs -ra

lxc exec server04 -- firewall-cmd --add-service=nfs --permanent >/dev/null 2>&1
lxc exec server04 -- firewall-cmd --add-service=rpc-bind --permanent >/dev/null 2>&1
lxc exec server04 -- firewall-cmd --add-service=mountd --permanent >/dev/null 2>&1
lxc exec server04 -- firewall-cmd --reload >/dev/null 2>&1

STORAGE_IP=$(lxc list -c n4 --format csv | grep "^server04," | awk -F',' '{print $2}' | awk '{print $1}')
echo "   ✅ NFS export ready on server04 ($STORAGE_IP:/exports/central-orders)"

# ==========================================
# STEP 5: Deploy the order-gen + order-sync services on fleet nodes
# ==========================================
echo ""
echo "🔧 Step 5: Deploying order-gen + order-sync services on fleet nodes..."

MOUNT_POINT="/mnt/central-orders"
MOUNT_UNIT='mnt-central\x2dorders.mount'

for i in {1..3}; do
    NODE="server0$i"

    lxc exec $NODE -- mkdir -p /var/spool/orders /var/lib/order-sync "$MOUNT_POINT"

    # order-gen: simulates real application traffic - a fake order every 20s
    lxc exec $NODE -- bash -c "cat > /usr/local/bin/order-gen.sh << 'SCRIPT'
#!/bin/bash
mkdir -p /var/spool/orders
echo \"{\\\"node\\\":\\\"\$(hostname)\\\",\\\"order_id\\\":\\\"\$(date +%s%N)\\\",\\\"ts\\\":\\\"\$(date -Is)\\\"}\" > /var/spool/orders/order-\$(date +%s%N).json
SCRIPT"
    lxc exec $NODE -- chmod +x /usr/local/bin/order-gen.sh

    lxc exec $NODE -- bash -c "cat > /etc/systemd/system/order-gen.service << 'EOF'
[Unit]
Description=Generate a simulated order file

[Service]
Type=oneshot
ExecStart=/usr/local/bin/order-gen.sh
EOF"

    lxc exec $NODE -- bash -c "cat > /etc/systemd/system/order-gen.timer << 'EOF'
[Unit]
Description=Run order-gen every 20s

[Timer]
OnBootSec=10s
OnUnitActiveSec=20s

[Install]
WantedBy=timers.target
EOF"

    # order-sync: pushes the local spool to the NFS-mounted central directory.
    # Deliberately depends on the mount unit — this is the piece that gets
    # dragged down when the mount's boot ordering is wrong.
    lxc exec $NODE -- bash -c "cat > /usr/local/bin/order-sync.sh << 'SCRIPT'
#!/bin/bash
LOG_FILE=/var/log/order-sync.log
mkdir -p $MOUNT_POINT/\$(hostname)
RESULT=\$(rsync -a /var/spool/orders/ $MOUNT_POINT/\$(hostname)/ 2>&1)
if [ \$? -eq 0 ]; then
    echo \"[\$(date)] sync OK\" >> \$LOG_FILE
    touch /var/lib/order-sync/last_ok
else
    echo \"[\$(date)] sync FAILED: \$RESULT\" >> \$LOG_FILE
fi
SCRIPT"
    lxc exec $NODE -- chmod +x /usr/local/bin/order-sync.sh

    lxc exec $NODE -- bash -c "cat > /etc/systemd/system/order-sync.service << 'EOF'
[Unit]
Description=Sync local orders to central NFS storage
RequiresMountsFor=$MOUNT_POINT
After=$MOUNT_UNIT

[Service]
Type=oneshot
ExecStart=/usr/local/bin/order-sync.sh
EOF"

    lxc exec $NODE -- bash -c "cat > /etc/systemd/system/order-sync.timer << 'EOF'
[Unit]
Description=Run order-sync every 60s

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s

[Install]
WantedBy=timers.target
EOF"

    # Liveness endpoint — a totally independent static check. It knows
    # nothing about the mount or the sync service, which is exactly what
    # makes it blind to this incident.
    lxc exec $NODE -- bash -c "mkdir -p /usr/share/nginx/html && echo 'OK' > /usr/share/nginx/html/health"
    lxc exec $NODE -- firewall-cmd --add-service=http --permanent >/dev/null 2>&1
    lxc exec $NODE -- firewall-cmd --reload >/dev/null 2>&1
done

echo "   ✅ order-gen + order-sync deployed, /health endpoint live on server01-03."

# ==========================================
# STEP 6: Write the NFS mount unit (correct ordering) on ALL fleet nodes
# ==========================================
echo ""
echo "🔧 Step 6: Writing the central-orders NFS mount unit (correct baseline)..."

for i in {1..3}; do
    NODE="server0$i"
    lxc exec $NODE -- bash -c "cat > '/etc/systemd/system/$MOUNT_UNIT' << EOF
[Unit]
Description=Central Orders NFS Mount
After=network-online.target
Wants=network-online.target

[Mount]
What=$STORAGE_IP:/exports/central-orders
Where=$MOUNT_POINT
Type=nfs
Options=defaults,_netdev,timeo=30

[Install]
WantedBy=remote-fs.target
EOF"
    lxc exec $NODE -- systemctl daemon-reload
    lxc exec $NODE -- systemctl enable --now "$MOUNT_UNIT" >/dev/null 2>&1
    lxc exec $NODE -- systemctl enable --now order-gen.timer order-sync.timer >/dev/null 2>&1
done

echo "   ✅ Baseline mount + timers enabled and running on all 3 fleet nodes."

# ==========================================
# STEP 7: Let real traffic accumulate before the maintenance reboot
# ==========================================
echo ""
echo "⏳ Step 7: Letting order-gen/order-sync run for 90s to build a healthy baseline..."
sleep 90

# ==========================================
# STEP 8: Inject the fault
# ==========================================
echo ""
echo "💥 Step 8: Injecting fault..."

# DO NOT READ — ROOT CAUSE
# One fleet node's NFS mount unit is rewritten WITHOUT network ordering
# (no After=/Wants=network-online.target) and re-hooked to local-fs.target
# instead of remote-fs.target. This means that on every future boot,
# systemd attempts the NFS mount during the early local-fs phase, before
# networking exists, so it fails ("Network is unreachable"). Because
# order-sync.service declares RequiresMountsFor=/mnt/central-orders, it
# fails too as a dependency failure, and the node's overall boot state
# becomes "degraded" (systemctl is-system-running). The nginx /health
# endpoint is a fully independent unit and keeps returning 200 OK, so
# external/LB monitoring never sees the problem.
FAULT_NODE="server02"

lxc exec $FAULT_NODE -- systemctl disable --now "$MOUNT_UNIT" >/dev/null 2>&1
lxc exec $FAULT_NODE -- bash -c "cat > '/etc/systemd/system/$MOUNT_UNIT' << EOF
[Unit]
Description=Central Orders NFS Mount

[Mount]
What=$STORAGE_IP:/exports/central-orders
Where=$MOUNT_POINT
Type=nfs
Options=defaults,_netdev,timeo=30

[Install]
WantedBy=local-fs.target
EOF"
lxc exec $FAULT_NODE -- systemctl daemon-reload
lxc exec $FAULT_NODE -- systemctl enable "$MOUNT_UNIT" >/dev/null 2>&1

# ==========================================
# STEP 9: Deploy incident ticket to MOTD (all nodes)
# ==========================================
echo ""
echo "🎫 Step 9: Deploying incident ticket to /etc/motd..."

TICKET='======================================================================
OPS-1091 - INCIDENT - P2
======================================================================
REPORTED BY: Central Orders Dashboard / Zabbix        TIME: 06:40 AM
SUMMARY: One fleet node stopped delivering orders to central storage
         after last night'"'"'s maintenance reboot
======================================================================
DESCRIPTION:
The order-gen/order-sync pipeline runs on server01-03 (HA fleet tier).
Each node generates order files locally and syncs them every minute to
a central NFS export on server04 (/exports/central-orders). A nightly
maintenance window rebooted all three fleet nodes at 03:00 AM.

Since that reboot, the central-orders dashboard on server04 shows order
files arriving from only two of the three fleet nodes. The load
balancer'"'"'s HTTP health checks against /health on all three nodes
continue to return 200 OK, and no nginx errors have been logged.

NOTES FROM PREVIOUS SHIFT (Night L1):
"Logged into server04 and checked the NFS export - nfs-server is
active, 'exportfs -v' shows /exports/central-orders exported correctly
to the fleet subnet, disk usage normal. Manually ran 'mount -t nfs
<server04>:/exports/central-orders /mnt/test' from a fleet node just to
double check and it mounted immediately without any error, files were
visible. Also pinged server04 from all three fleet nodes - 0% packet
loss. Concluded NFS itself is completely healthy and this is probably a
stale dashboard cache. Closed as false alarm."

CLIENT IMPACT:
Central order reconciliation depends on every fleet node'"'"'s orders
landing in /exports/central-orders. A node that keeps passing its load
balancer health check while silently failing to deliver orders after a
reboot can keep receiving production traffic indefinitely without
anyone noticing, until finance flags a reconciliation gap days later.

RESOLUTION CRITERIA:
1. Identify which fleet node stopped delivering orders after the
   maintenance reboot, and why.
2. Determine why the HTTP health check did not catch this.
3. Fix the root cause so the affected node reliably mounts central
   storage and resumes syncing on every future boot, not just this one.
4. Verify by checking order arrivals on server04 for all three nodes
   and confirming the affected node'"'"'s systemd boot state is no longer
   degraded.
5. Automate the fix in TWO idempotent playbooks:
   triage/triage-inc-010.yml (detect affected servers in a 1000-server fleet)
   remediation/remediate-inc-010.yml (fix only the affected servers)

PRIORITY: P2 - Silent degradation surviving reboots, monitoring blind spot.
======================================================================'

for i in {1..4}; do
    NODE="server0$i"
    lxc exec $NODE -- bash -c "cat > /etc/motd << 'MOTD'
$TICKET
MOTD"
done

# ==========================================
# STEP 10: Trigger the boot race (this is a "boot" incident)
# ==========================================
echo ""
echo "🔁 Step 10: Rebooting the fleet to trigger the maintenance-window boot race..."
for i in {1..3}; do
    lxc restart server0$i
done
echo "⏳ Waiting 40s for the fleet to come back up..."
sleep 40

# Re-arm the generator/sync timers is not needed - they're systemd-enabled
# and will come back on their own; the faulty node's mount unit will not.

echo "⏳ Waiting another 90s so a couple of sync cycles run post-reboot..."
sleep 90

# ==========================================
# STEP 11: Silent verification
# ==========================================
echo ""
echo "🔍 Verifying fault injection..."
VERIFY_OK=true

if ! lxc exec server04 -- systemctl is-active --quiet nfs-server 2>/dev/null; then
    VERIFY_OK=false
fi

if ! lxc exec server04 -- exportfs 2>/dev/null | grep -q "central-orders"; then
    VERIFY_OK=false
fi

for i in {1..4}; do
    NODE="server0$i"
    if ! lxc exec $NODE -- grep -q "OPS-1091" /etc/motd 2>/dev/null; then
        VERIFY_OK=false
    fi
done

for i in {1..3}; do
    NODE="server0$i"
    if ! lxc exec $NODE -- test -f /etc/systemd/system/order-sync.timer 2>/dev/null; then
        VERIFY_OK=false
    fi
    if ! lxc exec $NODE -- curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null | grep -q "200"; then
        VERIFY_OK=false
    fi
done

# Confirm exactly one fleet node is in a degraded boot state, without
# revealing which one.
DEGRADED_COUNT=0
for i in {1..3}; do
    NODE="server0$i"
    STATE=$(lxc exec $NODE -- systemctl is-system-running 2>/dev/null || true)
    if [ "$STATE" = "degraded" ]; then
        DEGRADED_COUNT=$((DEGRADED_COUNT+1))
    fi
done
if [ "$DEGRADED_COUNT" -ne 1 ]; then
    VERIFY_OK=false
fi

if [ "$VERIFY_OK" = true ]; then
    echo "✅ Fault injected successfully."
else
    echo "❌ ERROR: Fault injection failed."
    exit 1
fi

# ==========================================
# FINAL SUMMARY
# ==========================================
echo ""
echo "======================================================================"
echo "✅ LAB INC-010 READY"
echo "======================================================================"
echo ""
echo "📋 Summary:"
echo "   - Storage/NFS node: server04 (/exports/central-orders)"
echo "   - Fleet tier: server01, server02, server03"
echo "   - Central mount point (per node): /mnt/central-orders"
echo "   - Sync log (per node): /var/log/order-sync.log"
echo ""
echo "🎯 Your mission:"
echo "   1. Enter any node: lxc exec server01 -- bash"
echo "   2. Read the ticket: cat /etc/motd"
echo "   3. Compare order arrivals per node on server04 (/exports/central-orders)"
echo "   4. Find which node is degraded and why (hint: it's not the NFS server)"
echo "   5. Fix it so it survives future reboots, not just this session"
echo "   6. Explain why the HTTP health check didn't catch this"
echo "======================================================================"



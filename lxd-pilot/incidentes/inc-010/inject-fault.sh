#!/bin/bash
# inc-010 | inject-fault.sh
# Solo inyecta el fallo. La app ya fue desplegada por Ansible.
set -e

FAULT_NODE="server02"

echo "======================================================================"
echo "💥 INC-010 | Injecting fault into $FAULT_NODE"
echo "======================================================================"

# --- Inyectar el fallo: eliminar network ordering de s3-backend.service ---
# DO NOT READ — ROOT CAUSE
# s3-backend.service pierde After=network-online.target y Wants=network-online.target.
# Al bootear, systemd intenta verificar S3 antes de tener red → falla.
# order-sync.service tiene Requires=s3-backend.service → falla por dependencia.
# Boot queda "degraded". /health (nginx) sigue en 200 porque es independiente.

echo "   → Removing network ordering from s3-backend.service on $FAULT_NODE..."
lxc exec $FAULT_NODE -- systemctl disable --now s3-backend.service 2>/dev/null || true

lxc exec $FAULT_NODE -- bash -c "cat > /etc/systemd/system/s3-backend.service << 'EOF'
[Unit]
Description=S3 Backend Connectivity Check

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/s3-backend.sh

[Install]
WantedBy=multi-user.target
EOF"

lxc exec $FAULT_NODE -- systemctl daemon-reload
lxc exec $FAULT_NODE -- systemctl enable s3-backend.service 2>/dev/null || true
echo "   ✅ Fault injected."

# --- Escribir MOTD ticket en todos los nodos ---
echo "   → Deploying MOTD ticket..."

TICKET='======================================================================
OPS-1091 - INCIDENT - P2
======================================================================
REPORTED BY: Central Orders Dashboard / Prometheus     TIME: 06:40 AM
SUMMARY: One fleet node stopped delivering orders to central S3
storage after last night'"'"'s maintenance reboot
======================================================================
DESCRIPTION:
The order-gen/order-sync pipeline runs on server01-03 (HA fleet tier).
Each node generates order files locally and syncs them every minute to
a central S3 bucket (s3://central-orders) on the FakeCloud endpoint.
A nightly maintenance window rebooted all three fleet nodes at 03:00 AM.

Since that reboot, the central-orders dashboard shows order files
arriving from only two of the three fleet nodes. The load balancer'"'"'s
HTTP health checks against /health on all three nodes continue to
return 200 OK, and no nginx errors have been logged.

NOTES FROM PREVIOUS SHIFT (Night L1):
"Logged into the FakeCloud console and checked the S3 bucket - the
bucket exists, permissions look correct, and I can list objects from
my laptop without any issues. I also ran '"'"'aws s3 ls s3://central-orders'"'"'
manually from one of the healthy fleet nodes and it worked fine.
Also pinged the FakeCloud endpoint from all three fleet nodes - 0%
packet loss. Concluded S3 itself is completely healthy and this is
probably a stale dashboard cache. Closed as false alarm."

CLIENT IMPACT:
Central order reconciliation depends on every fleet node'"'"'s orders
landing in s3://central-orders. A node that keeps passing its load
balancer health check while silently failing to deliver orders after a
reboot can keep receiving production traffic indefinitely without
anyone noticing, until finance flags a reconciliation gap days later.

RESOLUTION CRITERIA:
1. Identify which fleet node stopped delivering orders after the
   maintenance reboot, and why.
2. Determine why the HTTP health check did not catch this.
3. Fix the root cause so the affected node reliably connects to S3
   and resumes syncing on every future boot, not just this one.
4. Verify by checking order arrivals in S3 for all three nodes
   and confirming the affected node'"'"'s systemd boot state is no longer
   degraded.
5. Automate the fix in TWO idempotent playbooks:
   triage/triage-inc-010.yml (detect affected servers in a 1000-server fleet)
   remediation/remediate-inc-010.yml (fix only the affected servers)

PRIORITY: P2 - Silent degradation surviving reboots, monitoring blind spot.
======================================================================'

for NODE in server01 server02 server03 monitoring; do
    lxc exec $NODE -- bash -c "cat > /etc/motd << 'MOTD'
$TICKET
MOTD"
done
echo "   ✅ MOTD ticket deployed."

# --- Rebootear la flota para disparar el race condition ---
echo "   → Rebooting fleet to trigger the boot race..."
for NODE in server01 server02 server03; do
    lxc restart $NODE
done

echo "⏳ Waiting 40s for fleet to come back..."
sleep 40
echo "⏳ Waiting 90s for sync cycles post-reboot..."
sleep 90

# --- Verificación silenciosa ---
echo ""
echo "🔍 Verifying fault injection..."
VERIFY_OK=true

for NODE in server01 server02 server03 monitoring; do
    if ! lxc exec $NODE -- grep -q "OPS-1091" /etc/motd 2>/dev/null; then
        VERIFY_OK=false
    fi
done

for NODE in server01 server02 server03; do
    if ! lxc exec $NODE -- test -f /etc/systemd/system/order-sync.timer 2>/dev/null; then
        VERIFY_OK=false
    fi
    if ! lxc exec $NODE -- curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null | grep -q "200"; then
        VERIFY_OK=false
    fi
done

DEGRADED_COUNT=0
for NODE in server01 server02 server03; do
    STATE=$(lxc exec $NODE -- systemctl is-system-running 2>/dev/null || true)
    if [ "$STATE" = "degraded" ]; then
        DEGRADED_COUNT=$((DEGRADED_COUNT+1))
    fi
done

if [ "$DEGRADED_COUNT" -ne 1 ]; then
    VERIFY_OK=false
fi

if [ "$VERIFY_OK" = true ]; then
    echo "✅ Fault injected successfully. Exactly 1 node degraded."
else
    echo "❌ ERROR: Fault injection failed."
    exit 1
fi

echo ""
echo "======================================================================"
echo "✅ INC-010 READY"
echo "======================================================================"
echo ""
echo "🎯 Your mission:"
echo "   1. Enter any node:  lxc exec server01 -- bash"
echo "   2. Read the ticket: cat /etc/motd"
echo "   3. Compare order arrivals per node in S3"
echo "   4. Find which node is degraded and why (hint: it's not S3)"
echo "   5. Fix it so it survives future reboots"
echo "   6. Explain why /health didn't catch this"
echo "======================================================================"

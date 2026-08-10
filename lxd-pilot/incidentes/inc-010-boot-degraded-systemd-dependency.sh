#!/bin/bash
# inc-010-boot-degraded-systemd-s3-dependency.sh
# Incident: One node in the fleet enters a "degraded" systemd boot state
# after a maintenance reboot because the S3 backend service is missing
# correct network ordering. The dependent sync service therefore fails to
# start too, but the HTTP liveness check is a completely separate service
# and keeps returning 200 OK.
#
# Architecture: Hybrid (LXD containers + FakeCloud S3)
# - server01-03: App fleet (already deployed by Terraform)
# - FakeCloud: S3 backend at http://10.45.223.1:4566
# - monitoring: Prometheus (already deployed by Terraform)
set -e

FAKECLOUD_ENDPOINT="http://10.45.223.1:4566"
BUCKET_NAME="central-orders"
AWS_CREDS_FILE="/root/.aws/credentials"
NODE_EXPORTER_TEXTFILE_DIR="/var/lib/node_exporter/textfile_collector"

echo "======================================================================"
echo "🚀 PREPARING LAB: INC-010 - Boot Degraded Systemd S3 Dependency"
echo "======================================================================"

# ==========================================
# STEP 0: Verify Terraform infrastructure exists
# ==========================================
echo ""
echo "🔍 Step 0: Verifying Terraform infrastructure..."
for NODE in server01 server02 server03 monitoring; do
    if ! lxc info $NODE &>/dev/null; then
        echo "   ❌ ERROR: $NODE does not exist. Run 'terraform apply' first."
        exit 1
    fi
done
echo "   ✅ All containers exist."

# Verify FakeCloud is reachable
if ! curl -s --max-time 5 $FAKECLOUD_ENDPOINT >/dev/null 2>&1; then
    echo "   ❌ ERROR: FakeCloud not reachable at $FAKECLOUD_ENDPOINT"
    exit 1
fi
echo "   ✅ FakeCloud is reachable."

# ==========================================
# STEP 1: Create S3 bucket in FakeCloud
# ==========================================
echo ""
echo "📦 Step 1: Creating S3 bucket '$BUCKET_NAME' in FakeCloud..."
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

aws --endpoint-url $FAKECLOUD_ENDPOINT s3 mb s3://$BUCKET_NAME 2>/dev/null || true
echo "   ✅ Bucket '$BUCKET_NAME' ready."

# ==========================================
# STEP 2: Install additional packages on fleet nodes
# ==========================================
echo ""
echo "📦 Step 2: Installing additional packages..."
for NODE in server01 server02 server03; do
    echo "   → $NODE: nginx, curl..."
    lxc exec $NODE -- dnf install -y nginx curl >/dev/null 2>&1
    lxc exec $NODE -- systemctl enable --now nginx >/dev/null 2>&1
done
echo "   ✅ Packages installed."

# ==========================================
# STEP 3: Deploy order-gen + s3-backend + order-sync on fleet nodes
# ==========================================
echo ""
echo "🔧 Step 3: Deploying order pipeline on fleet nodes..."

for NODE in server01 server02 server03; do
    lxc exec $NODE -- mkdir -p /var/spool/orders /var/lib/order-sync $NODE_EXPORTER_TEXTFILE_DIR

    # --- order-gen: simulates real application traffic ---
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

    # --- s3-backend: verifies S3 connectivity and "mounts" the backend ---
    lxc exec $NODE -- bash -c "cat > /usr/local/bin/s3-backend.sh << 'SCRIPT'
#!/bin/bash
LOG_FILE=/var/log/s3-backend.log
MOUNT_POINT=/mnt/central-orders

mkdir -p \$MOUNT_POINT

# Verify S3 connectivity
RESULT=\$(aws --endpoint-url $FAKECLOUD_ENDPOINT s3 ls s3://$BUCKET_NAME 2>&1)
if [ \$? -eq 0 ]; then
    echo \"[\$(date)] S3 backend connected\" >> \$LOG_FILE
    touch \$MOUNT_POINT/.s3-mounted
    echo \"[\$(date)] Backend mounted at \$MOUNT_POINT\" >> \$LOG_FILE
    exit 0
else
    echo \"[\$(date)] S3 backend FAILED: \$RESULT\" >> \$LOG_FILE
    exit 1
fi
SCRIPT"
    lxc exec $NODE -- chmod +x /usr/local/bin/s3-backend.sh

    lxc exec $NODE -- bash -c "cat > /etc/systemd/system/s3-backend.service << 'EOF'
[Unit]
Description=S3 Backend Connectivity Check
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/s3-backend.sh

[Install]
WantedBy=multi-user.target
EOF"

    # --- order-sync: pushes local spool to S3 ---
    lxc exec $NODE -- bash -c "cat > /usr/local/bin/order-sync.sh << 'SCRIPT'
#!/bin/bash
LOG_FILE=/var/log/order-sync.log
METRICS_FILE=$NODE_EXPORTER_TEXTFILE_DIR/order_sync.prom
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

mkdir -p $NODE_EXPORTER_TEXTFILE_DIR

RESULT=\$(aws --endpoint-url $FAKECLOUD_ENDPOINT s3 sync /var/spool/orders/ s3://$BUCKET_NAME/\$(hostname)/ 2>&1)
if [ \$? -eq 0 ]; then
    echo \"[\$(date)] sync OK\" >> \$LOG_FILE
    touch /var/lib/order-sync/last_ok
    echo \"order_sync_success 1\" > \$METRICS_FILE
    echo \"order_sync_last_success_timestamp \$(date +%s)\" >> \$METRICS_FILE
else
    echo \"[\$(date)] sync FAILED: \$RESULT\" >> \$LOG_FILE
    echo \"order_sync_success 0\" > \$METRICS_FILE
    echo \"order_sync_last_success_timestamp \$(date +%s)\" >> \$METRICS_FILE
fi
SCRIPT"
    lxc exec $NODE -- chmod +x /usr/local/bin/order-sync.sh

    lxc exec $NODE -- bash -c "cat > /etc/systemd/system/order-sync.service << 'EOF'
[Unit]
Description=Sync local orders to central S3 storage
Requires=s3-backend.service
After=s3-backend.service

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

    # --- /health endpoint (independent liveness check) ---
    lxc exec $NODE -- bash -c "mkdir -p /usr/share/nginx/html && echo 'OK' > /usr/share/nginx/html/health"

    # Reload and enable all services
    lxc exec $NODE -- systemctl daemon-reload
    lxc exec $NODE -- systemctl enable --now s3-backend.service >/dev/null 2>&1
    lxc exec $NODE -- systemctl enable --now order-gen.timer order-sync.timer >/dev/null 2>&1
done

echo "   ✅ order-gen + s3-backend + order-sync deployed on all 3 fleet nodes."

# ==========================================
# STEP 4: Configure Node Exporter with textfile collector
# ==========================================
echo ""
echo "🔧 Step 4: Configuring Node Exporter textfile collector..."
for NODE in server01 server02 server03; do
    lxc exec $NODE -- bash -c "cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter --collector.textfile.directory=$NODE_EXPORTER_TEXTFILE_DIR --collector.systemd
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF"
    lxc exec $NODE -- systemctl daemon-reload
    lxc exec $NODE -- systemctl restart node_exporter >/dev/null 2>&1
done
echo "   ✅ Node Exporter configured with textfile collector."

# ==========================================
# STEP 5: Inject Prometheus alert rule for this incident
# ==========================================
echo ""
echo "🔧 Step 5: Injecting Prometheus alert rule..."
MONITORING_IP=$(lxc list -c n4 --format csv | grep "^monitoring," | awk -F',' '{print $2}' | awk '{print $1}')

lxc exec monitoring -- bash -c "cat > /opt/prometheus/rules/inc-010-alerts.yml << 'EOF'
groups:
  - name: inc-010-order-sync
    rules:
      - alert: OrderSyncFailing
        expr: order_sync_success == 0
        for: 2m
        labels:
          severity: warning
          incident: inc-010
        annotations:
          summary: \"Order sync failing on {{ \$labels.instance }}\"
          description: \"The order-sync service has been failing for more than 2 minutes on {{ \$labels.instance }}.\"

      - alert: SystemdDegraded
        expr: node_systemd_unit_state{state=\"failed\"} > 0
        for: 1m
        labels:
          severity: critical
          incident: inc-010
        annotations:
          summary: \"Systemd unit failed on {{ \$labels.instance }}\"
          description: \"A systemd unit is in failed state on {{ \$labels.instance }}.\"
EOF"

# Update prometheus.yml to include rules directory
lxc exec monitoring -- bash -c "
if ! grep -q 'rule_files' /opt/prometheus/prometheus.yml; then
    sed -i '/scrape_configs:/i rule_files:\n  - /opt/prometheus/rules/*.yml' /opt/prometheus/prometheus.yml
fi
"

# Reload Prometheus
lxc exec monitoring -- bash -c "kill -HUP \$(cat /opt/prometheus/prometheus.pid 2>/dev/null) 2>/dev/null || pkill -HUP prometheus" || true
echo "   ✅ Alert rule injected and Prometheus reloaded."

# ==========================================
# STEP 6: Let real traffic accumulate
# ==========================================
echo ""
echo "⏳ Step 6: Letting order-gen/order-sync run for 90s to build a healthy baseline..."
sleep 90

# ==========================================
# STEP 7: Inject the fault
# ==========================================
echo ""
echo "💥 Step 7: Injecting fault..."

# DO NOT READ — ROOT CAUSE
# One fleet node's s3-backend.service is rewritten WITHOUT network ordering
# (no After=/Wants=network-online.target). This means that on every future
# boot, systemd attempts the S3 connectivity check during the early boot
# phase, before networking exists, so it fails. Because order-sync.service
# declares Requires=s3-backend.service, it fails too as a dependency
# failure, and the node's overall boot state becomes "degraded".
# The nginx /health endpoint is a fully independent unit and keeps
# returning 200 OK, so external/LB monitoring never sees the problem.

FAULT_NODE="server02"

lxc exec $FAULT_NODE -- systemctl disable --now s3-backend.service >/dev/null 2>&1
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
lxc exec $FAULT_NODE -- systemctl enable s3-backend.service >/dev/null 2>&1

echo "   ✅ Fault injected."

# ==========================================
# STEP 8: Deploy incident ticket to MOTD
# ==========================================
echo ""
echo "🎫 Step 8: Deploying incident ticket to /etc/motd..."

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

# ==========================================
# STEP 9: Trigger the boot race
# ==========================================
echo ""
echo "🔁 Step 9: Rebooting the fleet to trigger the maintenance-window boot race..."
for NODE in server01 server02 server03; do
    lxc restart $NODE
done
echo "⏳ Waiting 40s for the fleet to come back up..."
sleep 40

echo "⏳ Waiting another 90s so a couple of sync cycles run post-reboot..."
sleep 90

# ==========================================
# STEP 10: Silent verification
# ==========================================
echo ""
echo "🔍 Verifying fault injection..."
VERIFY_OK=true

# Check S3 bucket exists
if ! aws --endpoint-url $FAKECLOUD_ENDPOINT s3 ls s3://$BUCKET_NAME &>/dev/null; then
    VERIFY_OK=false
fi

# Check MOTD on all nodes
for NODE in server01 server02 server03 monitoring; do
    if ! lxc exec $NODE -- grep -q "OPS-1091" /etc/motd 2>/dev/null; then
        VERIFY_OK=false
    fi
done

# Check services exist on fleet nodes
for NODE in server01 server02 server03; do
    if ! lxc exec $NODE -- test -f /etc/systemd/system/order-sync.timer 2>/dev/null; then
        VERIFY_OK=false
    fi
    if ! lxc exec $NODE -- curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null | grep -q "200"; then
        VERIFY_OK=false
    fi
done

# Confirm exactly one fleet node is in a degraded boot state
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
echo "   - S3 Backend: s3://$BUCKET_NAME on FakeCloud ($FAKECLOUD_ENDPOINT)"
echo "   - Fleet tier: server01, server02, server03"
echo "   - Sync log (per node): /var/log/order-sync.log"
echo "   - Backend log (per node): /var/log/s3-backend.log"
echo "   - Prometheus: http://$MONITORING_IP:9090"
echo ""
echo "🎯 Your mission:"
echo "   1. Enter any node: lxc exec server01 -- bash"
echo "   2. Read the ticket: cat /etc/motd"
echo "   3. Compare order arrivals per node in S3"
echo "   4. Find which node is degraded and why (hint: it's not S3)"
echo "   5. Fix it so it survives future reboots, not just this session"
echo "   6. Explain why the HTTP health check didn't catch this"
echo "======================================================================"

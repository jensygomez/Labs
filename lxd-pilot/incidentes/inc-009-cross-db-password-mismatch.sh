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
EOF

echo "   ✅ inventory.ini written."

# ==========================================
# STEP 3: Install packages
# ==========================================
echo ""
echo "📦 Step 3: Installing packages..."

echo "   → server04 (storage/DB): postgresql-server, firewalld..."
lxc exec server04 -- dnf install -y postgresql-server postgresql-contrib firewalld >/dev/null 2>&1
lxc exec server04 -- postgresql-setup --initdb >/dev/null 2>&1

for i in {1..3}; do
    NODE="server0$i"
    echo "   → $NODE (fleet): postgresql (client), nginx, curl, firewalld..."
    lxc exec $NODE -- dnf install -y postgresql nginx curl firewalld >/dev/null 2>&1
    lxc exec $NODE -- systemctl enable --now nginx firewalld >/dev/null 2>&1
done

lxc exec server04 -- systemctl enable --now firewalld >/dev/null 2>&1

# ==========================================
# STEP 4: Configure PostgreSQL on server04 (real backend service)
# ==========================================
echo ""
echo "🔧 Step 4: Configuring PostgreSQL database on server04..."

DB_PASS_CURRENT="Pg2026Rotated!"

lxc exec server04 -- systemctl start postgresql

lxc exec server04 -- runuser -l postgres -c "psql -c \"CREATE DATABASE accountsdb;\"" >/dev/null 2>&1
lxc exec server04 -- runuser -l postgres -c "psql -c \"CREATE USER svc_account WITH PASSWORD '$DB_PASS_CURRENT';\"" >/dev/null 2>&1
lxc exec server04 -- runuser -l postgres -c "psql -d accountsdb -c \"GRANT ALL PRIVILEGES ON DATABASE accountsdb TO svc_account;\"" >/dev/null 2>&1
lxc exec server04 -- runuser -l postgres -c "psql -d accountsdb -c \"CREATE TABLE heartbeat (id SERIAL PRIMARY KEY, node TEXT NOT NULL, ts TIMESTAMP NOT NULL DEFAULT now());\"" >/dev/null 2>&1
lxc exec server04 -- runuser -l postgres -c "psql -d accountsdb -c \"GRANT ALL ON TABLE heartbeat TO svc_account; GRANT USAGE, SELECT ON SEQUENCE heartbeat_id_seq TO svc_account;\"" >/dev/null 2>&1

# Allow network connections from the fleet subnet with md5 auth
PG_HBA=$(lxc exec server04 -- runuser -l postgres -c "psql -t -P format=unaligned -c 'SHOW hba_file;'" | tr -d '\r')
PG_CONF=$(lxc exec server04 -- runuser -l postgres -c "psql -t -P format=unaligned -c 'SHOW config_file;'" | tr -d '\r')

lxc exec server04 -- bash -c "echo 'host    accountsdb    svc_account    10.45.223.0/24    md5' >> $PG_HBA"
lxc exec server04 -- bash -c "sed -i \"s/^#listen_addresses.*/listen_addresses = '*'/\" $PG_CONF"

lxc exec server04 -- systemctl restart postgresql
lxc exec server04 -- firewall-cmd --add-port=5432/tcp --permanent >/dev/null 2>&1
lxc exec server04 -- firewall-cmd --reload >/dev/null 2>&1

STORAGE_IP=$(lxc list -c n4 --format csv | grep "^server04," | awk -F',' '{print $2}' | awk '{print $1}')
echo "   ✅ PostgreSQL ready on server04 ($STORAGE_IP:5432), db=accountsdb, user=svc_account"

# ==========================================
# STEP 5: Deploy the heartbeat client + fake health endpoint on fleet nodes
# ==========================================
echo ""
echo "🔧 Step 5: Deploying account-service heartbeat client on fleet nodes..."

for i in {1..3}; do
    NODE="server0$i"

    lxc exec $NODE -- mkdir -p /etc/account-service /var/lib/account-service

    # Credentials file — this is the piece that can drift out of sync
    lxc exec $NODE -- bash -c "cat > /etc/account-service/db.env << 'EOF'
DB_HOST=$STORAGE_IP
DB_NAME=accountsdb
DB_USER=svc_account
DB_PASS=$DB_PASS_CURRENT
EOF"
    lxc exec $NODE -- chmod 600 /etc/account-service/db.env

    # Heartbeat script: writes a row to the DB every run
    lxc exec $NODE -- bash -c "cat > /usr/local/bin/heartbeat.sh << 'SCRIPT'
#!/bin/bash
source /etc/account-service/db.env
LOG_FILE=/var/log/heartbeat.log

RESULT=\$(PGPASSWORD=\"\$DB_PASS\" psql -h \"\$DB_HOST\" -U \"\$DB_USER\" -d \"\$DB_NAME\" \\
  -c \"INSERT INTO heartbeat (node, ts) VALUES ('\$(hostname)', now());\" 2>&1)

if [ \$? -eq 0 ]; then
    echo \"[\$(date)] heartbeat OK\" >> \$LOG_FILE
    touch /var/lib/account-service/last_ok
else
    echo \"[\$(date)] heartbeat FAILED: \$RESULT\" >> \$LOG_FILE
fi
SCRIPT"
    lxc exec $NODE -- chmod +x /usr/local/bin/heartbeat.sh

    # Cron: heartbeat every minute (this is the real, continuous fleet-wide traffic)
    lxc exec $NODE -- bash -c "echo '* * * * * root /usr/local/bin/heartbeat.sh' > /etc/cron.d/account-heartbeat"
    lxc exec $NODE -- chmod 644 /etc/cron.d/account-heartbeat
    lxc exec $NODE -- systemctl enable --now crond >/dev/null 2>&1 || lxc exec $NODE -- systemctl enable --now cronie >/dev/null 2>&1

    # Liveness endpoint — deliberately shallow: only proves nginx is up,
    # NOT that the DB write path works. This is what makes monitoring
    # report "green" while heartbeats silently fail.
    lxc exec $NODE -- bash -c "mkdir -p /usr/share/nginx/html && echo 'OK' > /usr/share/nginx/html/health"
    lxc exec $NODE -- firewall-cmd --add-service=http --permanent >/dev/null 2>&1
    lxc exec $NODE -- firewall-cmd --reload >/dev/null 2>&1
done

echo "   ✅ Heartbeat client + shallow /health endpoint deployed on server01-03."

# ==========================================
# STEP 6: Let healthy heartbeats accumulate before injecting the fault
# ==========================================
echo ""
echo "⏳ Step 6: Letting heartbeats run for 90s to build a healthy baseline..."
sleep 90

# ==========================================
# STEP 7: Inject the fault
# ==========================================
echo ""
echo "💥 Step 7: Injecting fault..."

# DO NOT READ — ROOT CAUSE
# One fleet node's local db.env still has the OLD password from before a
# credential rotation on server04. Its heartbeat.sh authenticates with the
# stale password, fails with "password authentication failed", but the
# script only logs to /var/log/heartbeat.log — it does not affect nginx or
# the shallow /health endpoint, so external monitoring sees the node as
# healthy while its writes to the DB have stopped.
FAULT_NODE="server03"
lxc exec $FAULT_NODE -- sed -i "s/^DB_PASS=.*/DB_PASS=Pg2025Legacy!/" /etc/account-service/db.env

# ==========================================
# STEP 8: Deploy incident ticket to MOTD (all nodes)
# ==========================================
echo ""
echo "🎫 Step 8: Deploying incident ticket to /etc/motd..."

TICKET='======================================================================
OPS-1090 - INCIDENT - P2
======================================================================
REPORTED BY: Account Service Dashboard / Zabbix      TIME: 09:10 AM
SUMMARY: One fleet node stopped reporting heartbeats to the central DB
======================================================================
DESCRIPTION:
The Account Service runs on server01-03 (HA fleet tier) and writes a
heartbeat row to the central PostgreSQL database on server04 every
minute. The monitoring dashboard queries the "heartbeat" table and
alerts when a known node has not written a row in over 10 minutes.

For the last few hours, one of the three fleet nodes has intermittently
(and now consistently) stopped appearing in the heartbeat table, while
its HTTP /health endpoint on port 80 continues to return 200 OK on
every check. Load balancer health checks show all three nodes as
healthy. No nginx errors have been reported.

NOTES FROM PREVIOUS SHIFT (Night L1):
"Logged into server04 and checked PostgreSQL - service is active,
accepting connections, disk usage normal, no errors in the postgresql
log around the alert time. Connected manually with psql as the
postgres superuser from server04 itself and ran a few test queries
against accountsdb - worked fine, no authentication issues at all.
Also checked network connectivity between the fleet and server04 with
a basic connectivity test - no packet loss. Concluded the database
itself is healthy and this is likely a monitoring/dashboard query bug,
not a real fleet issue. Closed as false alarm."

CLIENT IMPACT:
The heartbeat table is used by the on-call rotation to confirm which
fleet nodes are actually processing account-service traffic end to
end. A silently-degraded node that still passes load balancer health
checks can keep receiving production traffic while failing to record
its activity, which undermines incident response confidence fleet-wide.

RESOLUTION CRITERIA:
1. Identify which fleet node has stopped writing heartbeats and why.
2. Determine why the node still passes its HTTP health check despite
   the underlying failure.
3. Fix the root cause so heartbeats resume for the affected node.
4. Verify by tailing the heartbeat table on server04 and confirming
   all three fleet nodes are writing rows again.
5. Automate the fix in TWO idempotent playbooks:
   triage/triage-inc-009.yml (detect affected servers in a 1000-server fleet)
   remediation/remediate-inc-009.yml (fix only the affected servers)

PRIORITY: P2 - Silent degradation, monitoring blind spot across the fleet.
======================================================================'

for i in {1..4}; do
    NODE="server0$i"
    lxc exec $NODE -- bash -c "cat > /etc/motd << 'MOTD'
$TICKET
MOTD"
done

# ==========================================
# STEP 9: Silent verification
# ==========================================
echo ""
echo "🔍 Verifying fault injection..."
VERIFY_OK=true

if ! lxc exec server04 -- systemctl is-active --quiet postgresql 2>/dev/null; then
    VERIFY_OK=false
fi

if ! lxc exec server04 -- runuser -l postgres -c "psql -d accountsdb -c '\dt'" 2>/dev/null | grep -q heartbeat; then
    VERIFY_OK=false
fi

for i in {1..3}; do
    NODE="server0$i"
    if ! lxc exec $NODE -- test -f /etc/cron.d/account-heartbeat 2>/dev/null; then
        VERIFY_OK=false
    fi
    if ! lxc exec $NODE -- test -f /etc/account-service/db.env 2>/dev/null; then
        VERIFY_OK=false
    fi
    if ! lxc exec $NODE -- grep -q "OPS-1090" /etc/motd 2>/dev/null; then
        VERIFY_OK=false
    fi
done

if ! lxc exec server04 -- grep -q "OPS-1090" /etc/motd 2>/dev/null; then
    VERIFY_OK=false
fi

# Confirm exactly one fleet node has a password that differs from the DB's
# current password, without revealing which one.
MISMATCH_COUNT=0
for i in {1..3}; do
    NODE="server0$i"
    NODE_PASS=$(lxc exec $NODE -- grep "^DB_PASS=" /etc/account-service/db.env | cut -d'=' -f2)
    if [ "$NODE_PASS" != "$DB_PASS_CURRENT" ]; then
        MISMATCH_COUNT=$((MISMATCH_COUNT+1))
    fi
done
if [ "$MISMATCH_COUNT" -ne 1 ]; then
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
echo "✅ LAB INC-009 READY"
echo "======================================================================"
echo ""
echo "📋 Summary:"
echo "   - Storage/DB node: server04 (PostgreSQL, db=accountsdb)"
echo "   - Fleet tier: server01, server02, server03 (heartbeat every 1 min)"
echo "   - Credentials file (per node): /etc/account-service/db.env"
echo "   - Heartbeat log (per node): /var/log/heartbeat.log"
echo ""
echo "🎯 Your mission:"
echo "   1. Enter any node: lxc exec server01 -- bash"
echo "   2. Read the ticket: cat /etc/motd"
echo "   3. Query the heartbeat table on server04 and compare node coverage"
echo "   4. Find the root cause and fix it"
echo "   5. Explain why the HTTP health check didn't catch this"
echo "======================================================================"

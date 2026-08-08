#!/bin/bash
# inc-008-backup-readonly-destination.sh
# Incident: Nightly backups fail silently because the destination directory
# has the immutable attribute set. The backup script reports success but
# writes 0 bytes.

echo "======================================================================"
echo "🚀 PREPARING LAB: INC-008 - Backup Read-Only Destination"
echo "======================================================================"

# ==========================================
# PASO 1: Create 4 VMs (server01-04)
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

echo "⏳ Waiting 20s for VMs to boot and get DHCP IPs..."
sleep 20

# ==========================================
# PASO 2: Detect IPs and generate inventory.ini
# ==========================================
echo ""
echo "🌐 Step 2: Detecting DHCP-assigned IPs..."

cat > inventory.ini << 'EOF'
[all:vars]
ansible_user=root
ansible_ssh_common_args='-o StrictHostKeyChecking=no'

EOF

for i in {1..4}; do
    NODE="server0$i"
    IP=$(lxc list -c n4 --format csv | grep "^$NODE," | awk -F',' '{print $2}' | awk '{print $1}')
    
    if [ -z "$IP" ]; then
        echo "   ❌ ERROR: Could not get IP for $NODE"
        exit 1
    fi
    
    echo "   ✅ $NODE: $IP"
    echo "server0$i ansible_host=$IP" >> inventory.ini
done

echo "" >> inventory.ini
echo "[backup_server]" >> inventory.ini
echo "server01" >> inventory.ini
echo "" >> inventory.ini
echo "[fleet]" >> inventory.ini
echo "server02" >> inventory.ini
echo "server03" >> inventory.ini
echo "" >> inventory.ini
echo "[all_nodes:children]" >> inventory.ini
echo "backup_server" >> inventory.ini
echo "fleet" >> inventory.ini

# ==========================================
# PASO 3: Install minimal packages
# ==========================================
echo ""
echo "📦 Step 3: Installing packages (rsync, curl, logrotate)..."
for i in {1..4}; do
    NODE="server0$i"
    echo "   → Installing on $NODE..."
    lxc exec $NODE -- dnf install -y rsync curl logrotate e2fsprogs >/dev/null 2>&1
done

# ==========================================
# PASO 4: Setup backup infrastructure on server01
# ==========================================
echo ""
echo "🔧 Step 4: Setting up backup infrastructure on server01..."

# Create source data directory (simulating production data)
lxc exec server01 -- bash -c "mkdir -p /var/lib/appdata"
lxc exec server01 -- bash -c "for i in {1..50}; do dd if=/dev/urandom of=/var/lib/appdata/data_\$i.bin bs=1K count=100 2>/dev/null; done"

# Create backup destination directory
lxc exec server01 -- bash -c "mkdir -p /backup/destination"

# Deploy the backup script (with the silent failure bug)
lxc exec server01 -- bash -c "cat > /usr/local/bin/nightly-backup.sh << 'SCRIPT'
#!/bin/bash
# Nightly backup script - runs at 02:00 AM
BACKUP_SRC=\"/var/lib/appdata\"
BACKUP_DST=\"/backup/destination\"
LOG_FILE=\"/var/log/backup.log\"
DATE=\$(date +%Y%m%d)

echo \"[\$(date)] Starting nightly backup...\" >> \$LOG_FILE

# Copy data to backup destination
rsync -aq \$BACKUP_SRC/ \$BACKUP_DST/\$DATE/ 2>/dev/null

# BUG: Script always reports success, even if rsync fails
# (stderr is redirected to /dev/null, exit code not checked)
echo \"[\$(date)] Backup completed successfully.\" >> \$LOG_FILE
exit 0
SCRIPT"

lxc exec server01 -- chmod +x /usr/local/bin/nightly-backup.sh

# Run the backup once to create the initial "successful" state
lxc exec server01 -- /usr/local/bin/nightly-backup.sh

# ==========================================
# PASO 5: Inject the fault (immutable attribute)
# ==========================================
echo ""
echo "💥 Step 5: Injecting fault on server01..."

# DO NOT READ — ROOT CAUSE
# The backup destination directory has the immutable attribute set.
# Any attempt to create new files or subdirectories will fail with
# "Operation not permitted", but the backup script ignores the error.
lxc exec server01 -- chattr +i /backup/destination

# ==========================================
# PASO 6: Setup cron job for nightly backup
# ==========================================
echo ""
echo "⏰ Step 6: Scheduling nightly backup via cron..."

lxc exec server01 -- bash -c "cat > /etc/cron.d/nightly-backup << 'CRON'
# Nightly backup - runs at 02:00 AM
0 2 * * * root /usr/local/bin/nightly-backup.sh
CRON"

lxc exec server01 -- chmod 644 /etc/cron.d/nightly-backup

# ==========================================
# PASO 7: Deploy incident ticket to MOTD
# ==========================================
echo ""
echo "🎫 Step 7: Deploying incident ticket to /etc/motd..."

TICKET='======================================================================
OPS-1080 - INCIDENT - P2
======================================================================
REPORTED BY: Backup Monitoring System      TIME: 06:45 AM
SUMMARY: Nightly backups failing silently for the past 3 days
======================================================================
DESCRIPTION:
The nightly backup job (nightly-backup.sh) runs at 02:00 AM every day.
Monitoring shows the job completes with exit code 0, but the backup
directory size has been 0 bytes for the last 3 consecutive nights.
No alerts were triggered because the script does not validate the
actual write operation.

The backup destination is /backup/destination on server01.
The source data is in /var/lib/appdata (approximately 5MB).

NOTES FROM PREVIOUS SHIFT (Night L1):
"I logged into server01 and checked disk space - plenty of room (85%
free). I also reviewed the backup script syntax and it looks fine.
I even ran the script manually and it printed Backup completed
successfully. I checked /var/log/backup.log and the last 3 entries
all say success. I think this might be a monitoring false positive
or a reporting bug. Marking as resolved - cannot reproduce."

CLIENT IMPACT:
If server01 experiences a catastrophic failure, we have no recovery
point for the last 3 days of application data. This violates our
RPO (Recovery Point Objective) of 24 hours.

RESOLUTION CRITERIA:
1. Identify why backups are reporting success but writing 0 bytes.
2. Fix the root cause so new backups are written correctly.
3. Improve the backup script to validate writes and fail loudly.
4. Verify by running the backup manually and confirming data is present.
5. Automate the fix in TWO idempotent playbooks:
   triage/triage-inc-008.yml (detect affected servers in a 1000-server fleet)
   remediation/remediate-inc-008.yml (fix only the affected servers)

PRIORITY: P2 - Data protection at risk, potential for data loss.
======================================================================'

lxc exec server01 -- bash -c "cat > /etc/motd << 'MOTD'
$TICKET
MOTD"

# ==========================================
# PASO 8: Silent verification
# ==========================================
echo ""
echo "🔍 Verifying fault injection..."
VERIFY_OK=true

# Check backup script exists
if ! lxc exec server01 -- test -f /usr/local/bin/nightly-backup.sh 2>/dev/null; then
    VERIFY_OK=false
fi

# Check destination directory exists
if ! lxc exec server01 -- test -d /backup/destination 2>/dev/null; then
    VERIFY_OK=false
fi

# Check immutable attribute is set
if ! lxc exec server01 -- lsattr -d /backup/destination 2>/dev/null | grep -q -- '----i'; then
    VERIFY_OK=false
fi

# Check cron job is configured
if ! lxc exec server01 -- test -f /etc/cron.d/nightly-backup 2>/dev/null; then
    VERIFY_OK=false
fi

# Check MOTD is deployed
if ! lxc exec server01 -- grep -q "OPS-1080" /etc/motd 2>/dev/null; then
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
echo "✅ LAB INC-008 READY"
echo "======================================================================"
echo ""
echo "📋 Summary:"
echo "   - Backup server: server01"
echo "   - Backup source: /var/lib/appdata (~5MB)"
echo "   - Backup destination: /backup/destination"
echo "   - Backup script: /usr/local/bin/nightly-backup.sh"
echo "   - Cron schedule: 02:00 AM daily"
echo ""
echo "🎯 Your mission:"
echo "   1. SSH into server01: lxc exec server01 -- bash"
echo "   2. Read the ticket: cat /etc/motd"
echo "   3. Investigate why backups report success but write 0 bytes"
echo "   4. Find the root cause and fix it"
echo "   5. Improve the backup script to fail loudly"
echo ""
echo "🔍 Hint: The previous L1 said 'cannot reproduce'..."
echo "======================================================================"

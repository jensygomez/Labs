#!/bin/bash
# inc-011 | inject-fault.sh
# Fault: LV extended with lvextend but filesystem NOT grown (no resize2fs).
set -e

FAULT_NODE="server02"

echo "======================================================================"
echo "💥 INC-011 | Injecting fault into $FAULT_NODE"
echo "======================================================================"

# DO NOT READ — ROOT CAUSE
# /data is an ext4 filesystem on /dev/datavg/datalv. The filesystem is
# 200MB and nearly full. We run `lvextend -l +100%FREE` to grow the LV
# to the full VG (~512MB), but we DO NOT run resize2fs. So the LV is now
# ~512MB but the filesystem is still 200MB and full. `lvs` misleadingly
# shows a large LV; `df` shows the filesystem at ~95-100%.

echo "   → Filling /data on $FAULT_NODE..."
lxc exec $FAULT_NODE -- bash -c "dd if=/dev/urandom of=/data/fill.tmp bs=1M count=85 2>/dev/null" || true

echo "   → Extending LV WITHOUT growing the filesystem (the fault)..."
lxc exec $FAULT_NODE -- lvextend -l +100%FREE /dev/datavg/datalv
# NOTE: deliberately NOT running resize2fs here.

# --- MOTD ticket ---
echo "   → Deploying MOTD ticket..."
TICKET='======================================================================
OPS-1102 - INCIDENT - P2
======================================================================
REPORTED BY: Central Orders Dashboard / Prometheus     TIME: 09:15 AM
SUMMARY: Order-processing app on one fleet node can no longer write to
its /data volume; backups to S3 have stopped
======================================================================
DESCRIPTION:
The order-processing application runs on server01-03 (HA fleet tier).
On each node it writes working data to /data (an LVM-backed ext4 volume)
and periodically uploads its application log to the central S3 bucket
(s3://backup-logs).

Since ~08:30 AM, monitoring shows that on ONE fleet node the application
has stopped writing new records to /data, and its log uploads to S3 have
ceased. The other two nodes are healthy.

NOTES FROM L1 (escalated to you, L2):
"I logged into each node and checked the storage. On all of them, '"'"'lvs'"'"'
shows the logical volume '"'"'datalv'"'"' is present and healthy - in fact on
the affected node the LV is about 512MB, so there should be plenty of
room. '"'"'vgs'"'"' shows no errors. The loop device and disk image look fine.
I don'"'"'t think it'"'"'s a disk problem - the volume clearly has space.
Maybe the application itself is hung or has a bug. Escalating to L2 to
investigate the application."

CLIENT IMPACT:
Orders for this node are not being persisted and are not reaching the
central backup bucket. If left unresolved, order data for this node will
be lost and reconciliation will show a gap.

RESOLUTION CRITERIA:
1. Identify which fleet node'"'"'s /data volume is affected, and reconcile
   why the application cannot write even though '"'"'lvs'"'"' reports a large LV.
2. Explain the discrepancy between the logical volume size and the actual
   filesystem size / free space.
3. Restore the ability to write by growing the filesystem to fill the
   logical volume, without losing data.
4. Verify the application can write again and log uploads to S3 resume.
5. Automate detection and fix in TWO idempotent playbooks:
   triage/triage-inc-011.yml (detect affected servers in a 1000-server fleet)
   remediation/remediate-inc-011.yml (fix only the affected servers)

PRIORITY: P2 - Silent storage exhaustion, misleading '"'"'lvs'"'"' output.
======================================================================'

for NODE in server01 server02 server03 monitoring; do
    lxc exec $NODE -- bash -c "cat > /etc/motd << 'MOTD'
$TICKET
MOTD"
done
echo "   ✅ MOTD ticket deployed."

# --- Silent verification ---
echo ""
echo "🔍 Verifying fault injection..."
USE_PCT=$(lxc exec $FAULT_NODE -- df --output=pcent /data | tail -1 | tr -d ' %')
FS_KB=$(lxc exec $FAULT_NODE -- df --output=size /data | tail -1 | tr -d ' ')
LV_MB=$(lxc exec $FAULT_NODE -- lvs --noheadings --nosuffix --units m -o lv_size /dev/datavg/datalv | tr -d ' ' | cut -d. -f1)
FS_MB=$((FS_KB / 1024))

echo "   /data usage: ${USE_PCT}%  |  filesystem: ${FS_MB}MB  |  LV: ${LV_MB}MB"

if [ "$USE_PCT" -ge 90 ] && [ "$LV_MB" -gt "$((FS_MB + 100))" ]; then
    echo "✅ Fault injected: filesystem at ${USE_PCT}% but LV is ${LV_MB}MB (filesystem only ${FS_MB}MB)."
else
    echo "❌ ERROR: Fault injection failed."
    exit 1
fi

echo ""
echo "======================================================================"
echo "✅ INC-011 READY — no reboot needed for this one"
echo "======================================================================"
echo ""
echo "🎯 Your mission (L2):"
echo "   1. Read the ticket:  ansible all -i inventory.ini -m shell -a 'cat /etc/motd'"
echo "   2. Figure out WHICH node's /data is actually full"
echo "   3. Explain why 'lvs' says there's space but the app can't write"
echo "   4. Fix it (grow the filesystem, don't lose data)"
echo "   5. Confirm backups to s3://backup-logs resume"
echo "======================================================================"

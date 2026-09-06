ROLE: Act as a Senior SRE / SysAdmin Mentor. 
OBJECTIVE: Guide the L1 engineer (the user) to resolve the incident described in the ticket below. Foster critical thinking and apply a structured troubleshooting methodology. 

CRITICAL RULE: YOU DO NOT KNOW THE ROOT CAUSE OR ANY DECOYS. 
You only know what is written in the ticket. You must discover the truth alongside the user based *only* on the command outputs they provide. Do NOT guess the root cause prematurely.

TROUBLESHOOTING METHODOLOGY TO ENFORCE:
1. ISOLATE: Guide the user to bypass the load balancer and test direct access to each app_node IP to find the asymmetric failure.
2. DIAGNOSE: Ask the user to check filesystem and kernel health on the suspected node. Warn them that some commands (like `df -h`) might behave abnormally on broken mounts.
3. HYPOTHESIZE: Based *strictly* on the user's command outputs, ask them to connect the dots (e.g., "You mentioned the storage rebooted abruptly, and now `dmesg` shows X. What does that suggest about the mount state?").
4. REMEDIATE: Guide them to find the correct Linux mechanism to recover an unresponsive mount (hint: standard `umount` might hang, what are the alternatives?).
5. VERIFY: Ensure they test the VIP again and clean up any anomalous configurations they find.

INTERACTION RULES:
- Ask ONE guiding question at a time. Wait for the user's response.
- If the user reports "Permission denied" in Apache logs, DO NOT dismiss it as a decoy. Instead, guide them to verify if it's a true permission issue or a symptom of an underlying filesystem/kernel issue (e.g., "Let's verify the actual filesystem state before changing permissions. What does `dmesg -T | grep -i nfs` or `ls -la /var/www/html` show?").
- Praise good troubleshooting steps. Gently correct dead ends by asking probing questions.
- Keep your responses concise and focused on the next actionable step.

[TICKET DATA WILL BE PROVIDED BY THE USER NEXT]

======================================================================
TICKET ID: OPS-1104 | SEVERITY: P2 (Application / Storage Impact)
REPORTED BY: Marcus T. (NOC L1 - APAC Shift)
TIME: 02:17 AM CEST (Assigned to L1 Day Shift)
SUMMARY: Intermittent HTTP 500 errors on web application - "Unable to read files"
DESCRIPTION:
Greetings L1 Team,

We are receiving alerts from the monitoring system and reports from the 
DevOps team that the web application (accessed via VIP 10.10.10.30) is 
returning intermittent HTTP 500 Internal Server Error responses.

The behavior is INTERMITTENT and ASYMMETRIC:
- Some page loads succeed normally (Apache serves content correctly).
- Other page loads fail with HTTP 500, with Apache error logs showing:
  "Permission denied" or "Unable to open file" errors.
- The issue appears to affect approximately 30-40% of requests.

Context:
Last night at 23:45, the storage team performed an "emergency firmware 
update" on storage01 (10.10.10.50). The node was rebooted abruptly 
(without graceful NFS shutdown). Since then, the web application has 
been exhibiting inconsistent behavior.

BUSINESS IMPACT:
- End users are experiencing intermittent failures when accessing the 
  web application.
- Client traffic generators (client01-04) are reporting failed 
  transactions and missing evidence files in /var/www/html/uploads.
- If not resolved, the SLA breach threshold will be reached within 2 hours.
- The next scheduled batch consolidation (client04) will fail if the 
  storage issue persists.

INITIAL TROUBLESHOOTING DONE (BY NOC):
1. Verified Apache status on all app_nodes:
   - app01, app02, app03: httpd is Active (running) on all nodes.

2. Checked Apache error logs on all nodes:
   - Some nodes show "Permission denied: access to /index.php denied" 
     (Note: This might be misleading, verify actual file access).

3. Verified network connectivity:
   - All app_nodes can ping storage01 (10.10.10.50) successfully.
   - NFS ports (2049, 111) are reachable from all app_nodes.

4. Checked disk space on all app_nodes:
   - All nodes show adequate free space on / (local filesystem).
   - NOTE: The command `df -h` hangs or shows errors on ONE of the 
     app_nodes when trying to display the NFS mount.

5. Verified NFS service on storage01:
   - nfs-server is Active (running) on storage01.
   - exportfs -v shows /exports/webdata is exported correctly.

CRITICAL OBSERVATION:
When testing HTTP access directly to each app_node's individual IP 
(10.10.10.31, .32, .33), the NOC team noticed that ONE specific node 
is consistently returning HTTP 500 errors, while the other two return 
HTTP 200 OK. However, due to the round-robin nature of HAProxy, accessing 
via the VIP (10.10.10.30) results in the intermittent failures reported.

EXPECTED ACTION FROM L1:
1. Identify which specific app_node is returning HTTP 500 errors by 
   testing direct access to each node's IP.
2. On the affected node, investigate the NFS mount status:
   - Run `df -h` and observe if it hangs or shows "Stale file handle".
   - Run `mount | grep nfs` to verify mount points.
   - Attempt to access /var/www/html and check for errors.
3. Recover the stale NFS mount on the affected node:
   - Force unmount the stale mount (umount -f or umount -l).
   - Remount the NFS share (mount -a or explicit mount command).
   - Verify the mount is functional (df -h, ls /var/www/html).
4. Clean up any misleading configuration or logs that may have been 
   added during the storage team's emergency maintenance.
5. Verify HTTP access works consistently via the VIP after the fix.
6. Provide Root Cause Analysis (RCA) once resolved.

Best Regards,
Marcus T.
NOC L1 Support | Global IT Services


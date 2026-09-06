======================================================================
TICKET ID: OPS-1103 | SEVERITY: P2 (Access / Operational Impact)
REPORTED BY: Priya S. (NOC L1 - EMEA Shift)
TIME: 10:42 AM CEST (Assigned to L1 Day Shift)
SUMMARY: Intermittent authentication failures for admin user 'jensyg' across the applicative cluster via VIP.
DESCRIPTION:
Greetings L1 Team,

We are receiving reports from the DevOps team that they CANNOT consistently SSH into the applicative cluster using the administrative account 'jensyg' via the VIP (10.10.10.30). 

The authentication behavior is INTERMITTENT:
- Some login attempts succeed.
- Other login attempts are rejected with "Authentication failed" or "Account expired" messages.
- The team confirms the password is correct (tested from a different jump host with the same credentials and it works 100% of the time on non-cluster targets).

Context:
Yesterday evening, the security team performed a "routine credential rotation audit" across the applicative cluster (app01, app02, app03). Since then, the jensyg account has been exhibiting inconsistent behavior depending on which backend node answers the request.

BUSINESS IMPACT:
- DevOps team cannot reliably deploy new PHP code to the cluster.
- Ansible playbooks targeting the cluster with the jensyg identity are failing intermittently.
- Monitoring agent on the cluster is reporting "credential refresh failed" on some nodes.
- If not resolved, the next scheduled deployment window will be missed.

INITIAL TROUBLESHOOTING DONE (BY NOC):
- Verified password is correct by testing on a non-cluster target (login successful 100%).
- Checked SSH service on all app nodes: `systemctl status sshd` → Active/Running on all.
- Checked /var/log/secure on all app nodes:
  * app01: shows successful logins for jensyg.
  * app02: shows successful logins for jensyg.
  * app03: shows successful logins for jensyg.
  * NOTE: No authentication failures visible in recent logs on ANY node.
- Checked /etc/passwd and /etc/shadow on all nodes: user entry exists, no typos.
- Verified network and DNS resolution to all app nodes is fine.
- firewalld on all app nodes allows SSH (22/tcp).
- HAProxy health checks are passing on all app nodes (HTTP 200 on port 80).
- CRITICAL OBSERVATION: When testing SSH directly to each node's individual IP (10.10.10.31, .32, .33), logins succeed 100% of the time. But when using the VIP (10.10.10.30), authentication fails intermittently.

EXPECTED ACTION FROM L1:
1. Investigate why authentication fails intermittently via VIP despite working when connecting directly to each node.
2. Check account aging/expiration status on EACH node individually (chage, passwd -S).
3. Check /etc/shadow for lock indicators ('!' or '!!' prefix) on each node.
4. Identify which specific node(s) have the account in a broken state.
5. Restore the account to a usable state on the affected node(s).
6. Verify SSH login works consistently via the VIP after the fix.
7. Provide Root Cause Analysis (RCA) once resolved.

Best Regards,
Priya S.
NOC L1 Support | Global IT Services

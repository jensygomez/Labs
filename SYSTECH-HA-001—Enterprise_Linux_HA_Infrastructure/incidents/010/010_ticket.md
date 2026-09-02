======================================================================
TICKET ID: OPS-1103 | SEVERITY: P2 (Access / Operational Impact)
REPORTED BY: Priya S. (NOC L1 - EMEA Shift)
TIME: 10:42 AM CEST (Assigned to L1 Day Shift)
SUMMARY: Administrative user 'jensyg' cannot authenticate on app01 despite correct password.
DESCRIPTION:
Greetings L1 Team,
We are receiving reports from the DevOps team that they cannot SSH into
app01 (10.10.10.31) using the administrative account 'jensyg'. The team
confirms the password is correct (tested from a different jump host with
the same credentials and it works), but authentication is rejected on
app01 specifically.

Context:
Yesterday evening, the security team performed a "routine credential
rotation audit" across the applicative cluster. Since then, the jensyg
account on app01 has been refusing logins.

BUSINESS IMPACT:
- DevOps team cannot deploy new PHP code to app01.
- Ansible playbooks targeting app01 with the jensyg identity are failing.
- Monitoring agent on app01 is reporting "credential refresh failed".
- If not resolved, the next scheduled deployment window will be missed.

INITIAL TROUBLESHOOTING DONE (BY NOC):
- Verified password is correct by testing on app02 (login successful).
- Checked SSH service on app01: `systemctl status sshd` → Active/Running.
- Checked /var/log/secure on app01: shows "Authentication failure" and
  "Account expired" messages for user jensyg.
- Checked /etc/passwd and /etc/shadow: user entry exists, no typos.
- Verified network and DNS resolution to app01 is fine.
- firewalld on app01 allows SSH (22/tcp).

EXPECTED ACTION FROM L1:
- Investigate why authentication fails despite correct credentials.
- Check account aging/expiration status (chage, passwd -S).
- Check /etc/shadow for lock indicators ('!' or '!!' prefix).
- Restore the account to a usable state.
- Verify SSH login works after the fix.
- Provide Root Cause Analysis (RCA) once resolved.

Best Regards,
Priya S.
NOC L1 Support | Global IT Services

======================================================================
TICKET ID: OPS-1073 | SEVERITY: P2 (Access Degraded)
REPORTED BY: Automation Pipeline / Junior Developer
TIME: 08:15 AM (Assigned to L1 Day Shift)
SUMMARY: Developer cannot access app01 via SSH using their public key.
DESCRIPTION:
An automated deployment script was executed on app01 by a junior admin.
Since then, the user 'devuser' is unable to log in via SSH using their 
authorized SSH key. Password authentication is disabled for this user.

ERROR REPORTED BY CLIENT:
"Permission denied (publickey)."

CUSTOMER IMPACT:
CI/CD deployments are blocked because the deployment user cannot connect.

RESOLUTION WORKFLOW (L1 STANDARD OPERATING PROCEDURE):
1. Verify SSH permissions standards according to OpenSSH security policies:
   - User home directory (~): max 0755 (must not be group/world writable)
   - ~/.ssh directory: strictly 0700
   - ~/.ssh/authorized_keys: strictly 0600 or 0644
2. Check SSH daemon logs on the target server:
   - `journalctl -u sshd -n 50` or `grep sshd /var/log/secure` (or /var/log/auth.log)
   - Look for errors like "Authentication refused: bad ownership or modes for directory/file".
3. Identify which path level has incorrect permissions and fix it using `chmod`.
======================================================================

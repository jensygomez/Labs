======================================================================
TICKET ID: OPS-1073 | SEVERITY: P2 (Access Degraded)
REPORTED BY: Automation Pipeline / Junior Developer
TIME: 08:15 AM (Assigned to L1 Day Shift)
SUMMARY: Developer cannot access an application node via SSH using their public key.
DESCRIPTION:
An automated deployment script was executed on one of the application nodes 
by a junior admin. Since then, the user 'devuser' (or the configured 
deployment user) is unable to log in via SSH using their authorised SSH key. 
Password authentication is disabled for this user.

ERROR REPORTED BY CLIENT:
"Permission denied (publickey)."

CUSTOMER IMPACT:
CI/CD deployments are blocked because the deployment user cannot connect 
to the affected node.

RESOLUTION WORKFLOW (L1 STANDARD OPERATING PROCEDURE):
1. Identify the affected node by checking the SSH error logs or testing 
   connectivity to each app node.
2. Verify SSH permissions standards according to OpenSSH security policies:
   - User home directory (~): max 0755 (must not be group/world writable)
   - ~/.ssh directory: strictly 0700
   - ~/.ssh/authorized_keys: strictly 0600 or 0644
3. Check SSH daemon logs on the affected server:
   - `journalctl -u sshd -n 50` or `grep sshd /var/log/secure` (or /var/log/auth.log)
   - Look for errors like "Authentication refused: bad ownership or modes for directory/file".
4. Identify which path level has incorrect permissions and fix it using `chmod`.
5. Test SSH access with the developer's key before closing the ticket.
======================================================================

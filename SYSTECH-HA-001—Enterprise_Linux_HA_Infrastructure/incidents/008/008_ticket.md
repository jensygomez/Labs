======================================================================
TICKET ID: OPS-1088 | SEVERITY: P2 (Service Degraded)
REPORTED BY: Monitoring Team (HAProxy alerts)
TIME: 10:30 AM (Assigned to L1 Day Shift)
SUMMARY: One of the application nodes is not responding to HTTP requests, causing 503 errors in HAProxy.
DESCRIPTION:
HAProxy is reporting that one of the backend nodes (app01/app02/app03) is marked as "DOWN" due to connection timeouts. The node is still reachable via SSH, and Apache appears to be running, but it does not respond to HTTP requests from the load balancer.

CUSTOMER IMPACT:
Approximately 33% of web requests fail with HTTP 503 errors. The cluster is partially degraded.

TROUBLESHOOTING STEPS (L1 SOP):
1. Identify which node is down by checking HAProxy stats or logs:
   `journalctl -u haproxy | grep -i "down\|503"`
2. SSH into the affected node and verify Apache is listening:
   `ss -tlnp | grep :80`
3. Check if the local firewall is blocking HTTP traffic:
   `sudo firewall-cmd --list-all`
   (Look for the 'http' service in the list. If missing, it's blocked.)
4. Temporarily open the port and test:
   `sudo firewall-cmd --add-service=http --permanent`
   `sudo firewall-cmd --reload`
5. Verify connectivity from another node:
   `curl -I http://<affected-node-ip>`
6. If firewall was the issue, document and close the ticket.
======================================================================

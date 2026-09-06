======================================================================
TICKET ID: OPS-1068 | SEVERITY: P2 (Service Degradation)
REPORTED BY: Automated Monitoring (Client Traffic Script) & End-User Reports
TIME: 11:20 AM (Assigned to L1 Day Shift)
SUMMARY: HTTP 403 Forbidden errors on the application VIP
DESCRIPTION:
The continuous traffic monitoring script is reporting HTTP 403 
(Forbidden) responses against the application VIP (10.10.10.30). 

ICMP ping and SSH connectivity to all 3 nodes in the application 
fleet (app01/app02/app03) are successful.

Context: A developer from the application team mentioned they needed 
to test a quick PHP hotfix and performed a "manual direct deployment" 
on one of the backend nodes about 30 minutes ago. Shortly after, 
the monitoring system started alerting on 403 errors. 

HAProxy is still routing traffic, but requests hitting the affected 
node are failing immediately. The other two nodes seem to be serving 
traffic normally, but the overall error rate is impacting the user 
experience.

CUSTOMER IMPACT: 
Users are receiving "Access Denied" (403) pages when the load balancer 
routes their session to the affected backend node.
======================================================================
RESOLUTION WORKFLOW (L1 STANDARD OPERATING PROCEDURE):

1. Verify the symptom from the client side:
   ssh ansible@10.10.10.11 "sudo journalctl -u infinite-traffic.service -f -n 30 --no-pager"
   (Observe the 403 errors and identify if they are tied to a specific node).

2. Identify the root cause manually via CLI. 
   Investigate the affected application node. Check web server logs, 
   file system permissions, and security modules.
   Useful commands: `tail -f /var/log/httpd/error_log`, 
   `journalctl -u httpd -n 50`, `ls -laZ /var/www/html/`, 
   `namei -om /var/www/html/index.php`.

3. Resolve the issue manually on the affected node (hotfix) and 
   confirm from the client side:
   ssh ansible@10.10.10.11 "/usr/local/bin/infinite_traffic.sh"
   (Compare against step 1).

4. AUTOMATION CHALLENGE: 
   This time, resolve it 100% automated and idempotently. Write a new 
   remediation playbook (yours) that detects and fixes the root cause 
   without manual intervention, and that doesn't fail if executed 
   against a node that is already healthy.
======================================================================

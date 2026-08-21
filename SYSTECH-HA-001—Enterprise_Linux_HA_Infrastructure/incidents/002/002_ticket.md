======================================================================
TICKET ID: OPS-1055 | SEVERITY: P2 (Service Degradation)
REPORTED BY: Automated Monitoring (Client Traffic Script) & End-User Reports
TIME: 09:45 AM (Assigned to L1 Day Shift)
SUMMARY: Intermittent HTTP 500 errors and application instability on the VIP
DESCRIPTION:
The continuous traffic monitoring script is reporting sporadic HTTP 500 
(Internal Server Error) and 502 (Bad Gateway) responses against the 
application VIP (10.10.10.30). 

ICMP ping to all 3 nodes in the application fleet (app01/app02/app03) 
is successful. SSH connectivity is also confirmed, though some internal 
users report that SSH sessions feel "sluggish" or drop unexpectedly.

Context: Last night, the security team deployed a new "compliance and 
telemetry daemon" across the application fleet to meet new corporate 
audit requirements. Following this deployment, the web application has 
become highly unstable. 

HAProxy health checks are flapping; nodes are briefly marked as DOWN 
and then come back UP, causing intermittent 502s for the end users. 
Some backend services appear to be crashing and restarting on their own.

CUSTOMER IMPACT: 
Users are experiencing HTTP 500 errors and timeouts during the checkout 
process. The application is effectively unusable for a significant 
percentage of requests.
======================================================================
RESOLUTION WORKFLOW (L1 STANDARD OPERATING PROCEDURE):

1. Verify the symptom from the client side:
   ssh ansible@10.10.10.11 "/usr/local/bin/infinite_traffic.sh"
   (Observe the error rates, latency, and which nodes are failing).

2. Identify the root cause manually via CLI. 
   Investigate the application nodes (app01/02/03). Check service 
   statuses, system resources, and recent daemon deployments.
   Useful commands: `systemctl status httpd`, `journalctl -p err -n 50`, 
   `dmesg -T | tail -n 50`, `top`.

3. Resolve the issue manually on the affected node(s) (hotfix) and 
   confirm from the client side:
   ssh ansible@10.10.10.11 "/usr/local/bin/infinite_traffic.sh"
   (Compare against step 1).

4. Restore the system to its pre-incident state using the recovery playbook:
   ansible-playbook "002_Recuperacion_al_estado_anterior.yml"

5. Re-inject the incident:
   ansible-playbook "002_incidente.yml"

6. AUTOMATION CHALLENGE: 
   This time, resolve it 100% automated and idempotently. Write a new 
   remediation playbook (yours) that detects and fixes the root cause 
   without manual intervention, and that doesn't fail if executed 
   against a node that is already healthy.
======================================================================

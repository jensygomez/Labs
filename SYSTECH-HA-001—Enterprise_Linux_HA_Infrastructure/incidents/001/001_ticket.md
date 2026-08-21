======================================================================
TICKET ID: OPS-1042 | SEVERITY: P2 (Degraded Service)
REPORTED BY: Automated Monitoring (Client Traffic Script)
TIME: 08:15 AM (Assigned to L1 Day Shift)
SUMMARY: Intermittent 502 errors and high latency on the application VIP
DESCRIPTION:
The continuous traffic monitoring script is reporting sporadic HTTP 502 
errors against the application VIP (10.10.10.100). 

ICMP ping to all 3 nodes in the application fleet (app01/app02/app03) 
is successful. 

Context: Last night's scheduled maintenance window included a kernel 
reboot across the fleet, along with a hardening playbook that 
standardized the Apache listening port to 8099 on all nodes (new 
corporate port standard). 

The load balancer (HAProxy) is routing traffic, but the client reports 
intermittent slowness because the fleet is operating at reduced 
capacity (HAProxy health checks show only 2 out of 3 backends as healthy).

CUSTOMER IMPACT: 
Intermittent latency and sporadic 502 errors during the checkout process.
======================================================================
RESOLUTION WORKFLOW (L1 STANDARD OPERATING PROCEDURE):

1. Verify the symptom from the client side:
   ssh ansible@10.10.10.11 "/usr/local/bin/infinite_traffic.sh"
   (Save the output to compare later).

2. Identify the root cause manually via CLI. 
   Suspect the node (app01/02/03) that is not responding correctly 
   behind HAProxy. 
   Useful commands: `systemctl status httpd`, `journalctl -u httpd -n 50`, 
   `ss -tlnp | grep httpd`, `ausearch -m avc -ts recent`.

3. Resolve the issue manually on the affected node (hotfix) and 
   confirm from the client side:
   ssh ansible@10.10.10.11 "/usr/local/bin/infinite_traffic.sh"
   (Compare against step 1).

4. Restore the system to its pre-incident state using the recovery playbook:
   ansible-playbook "Recuperacion al estado anterior del incidente.yml"

5. Re-inject the incident:
   ansible-playbook "Apache no arranca tras mantenimiento.yml"

6. AUTOMATION CHALLENGE: 
   This time, resolve it 100% automated and idempotently. Write a new 
   remediation playbook (yours) that detects and fixes the root cause 
   without manual intervention, and that doesn't fail if executed 
   against a node that is already healthy.
======================================================================

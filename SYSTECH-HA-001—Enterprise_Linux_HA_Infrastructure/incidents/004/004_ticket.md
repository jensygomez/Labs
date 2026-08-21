======================================================================
TICKET ID: OPS-1071 | SEVERITY: P2 (Service Degradation)
REPORTED BY: Automated Monitoring (Client Traffic Script) & HAProxy Alerts
TIME: 10:30 AM (Assigned to L1 Day Shift)
SUMMARY: Backend node dropped from HAProxy pool after overnight reboot
DESCRIPTION:
The continuous traffic monitoring script is reporting HTTP 502 
(Bad Gateway) errors against the application VIP (10.10.10.30). 

ICMP ping and SSH connectivity to all 3 nodes in the application 
fleet (app01/app02/app03) are successful. However, HAProxy health 
checks show that one of the backend nodes is not responding on 
port 80.

Context: The infrastructure team performed an emergency kernel 
security update (CVE-2026-XXXX) on one of the application nodes 
late last night. The node was rebooted to apply the new kernel. 
The update process completed successfully according to the 
automation logs, but shortly after the reboot, the monitoring 
system started alerting that the node is not serving web traffic.

The affected node appears to be online and accessible via SSH, 
but the web server service is not running. HAProxy has 
automatically removed it from the rotation to protect users, 
but this leaves the cluster operating at reduced capacity 
(2 of 3 nodes).

CUSTOMER IMPACT: 
Intermittent 502 errors when the load balancer attempts to route 
traffic to the affected backend. Overall application performance 
is degraded due to reduced capacity.
======================================================================
RESOLUTION WORKFLOW (L1 STANDARD OPERATING PROCEDURE):

1. Verify the symptom from the client side:
   ssh ansible@10.10.10.11 "/usr/local/bin/infinite_traffic.sh"
   (Observe the 502 errors and identify if they correlate with 
   a specific node being absent from the rotation).

2. Identify the root cause manually via CLI. 
   SSH into the affected application node and investigate why 
   the web service is not running post-reboot.
   Useful commands: `systemctl status httpd`, 
   `systemctl list-unit-files | grep httpd`, 
   `journalctl -b -u httpd -n 50`, 
   `last reboot | head -n 5`.

3. Resolve the issue manually on the affected node (hotfix) and 
   confirm from the client side:
   ssh ansible@10.10.10.11 "/usr/local/bin/infinite_traffic.sh"
   (Compare against step 1).

4. Restore the system to its pre-incident state using the recovery playbook:
   ansible-playbook "004_Recuperacion_al_estado_anterior.yml"

5. Re-inject the incident:
   ansible-playbook "004_incidente.yml"

6. AUTOMATION CHALLENGE: 
   This time, resolve it 100% automated and idempotently. Write a new 
   remediation playbook (yours) that detects and fixes the root cause 
   without manual intervention, and that doesn't fail if executed 
   against a node that is already healthy.
======================================================================

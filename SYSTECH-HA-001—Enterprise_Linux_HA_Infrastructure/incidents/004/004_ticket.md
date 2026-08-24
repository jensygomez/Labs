======================================================================
TICKET ID: OPS-1071 | SEVERITY: P2 (Service Degradation)
REPORTED BY: Automated Monitoring (Client Traffic Script) & HAProxy Alerts
TIME: 10:30 AM (Assigned to L1 Day Shift)
SUMMARY: Backend node dropped from HAProxy pool after overnight reboot
DESCRIPTION:
The continuous traffic monitoring script is reporting HTTP 502
(Bad Gateway) errors against the application VIP (10.10.10.30).
ICMP ping and SSH connectivity to all 3 nodes in the application
fleet (app01/app02/app03.lab.systech.local) are successful. 
However, HAProxy health checks show that one of the backend nodes 
is not responding on port 80.

Context: The infrastructure team performed an emergency kernel
security update on one of the application nodes late last night. 
The node was rebooted to apply the new kernel. The update process 
completed successfully, but shortly after the reboot, the monitoring 
system started alerting that the node is not serving web traffic.

The affected node appears to be online and accessible via SSH,
but the web server service is not running. HAProxy has automatically
removed it from the rotation.

CUSTOMER IMPACT:
Intermittent 502 errors when the load balancer attempts to route
traffic to the affected backend.

RESOLUTION WORKFLOW (L1 STANDARD OPERATING PROCEDURE):
1. Verify the symptom from the client side:
   - ssh ansible@client01.lab.systech.local "/usr/local/bin/infinite_traffic.sh"
   (Observe the 502 errors).

2. Identify the root cause manually via CLI on the affected node.
   - Check service status: `systemctl status httpd`
   - Check boot persistence: `systemctl list-unit-files | grep httpd`
   - Check logs: `tail -n 50 /var/log/httpd/error_log`
   - Verify DNS resolution (Don't get distracted!): `dig app02.lab.systech.local`

3. Resolve the issue manually (hotfix) and confirm.

AUTOMATION CHALLENGE:
Write a remediation playbook that detects and fixes the root cause
without manual intervention, ensuring the service survives future reboots.
======================================================================

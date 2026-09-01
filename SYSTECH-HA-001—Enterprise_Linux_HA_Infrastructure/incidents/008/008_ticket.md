======================================================================
TICKET ID: OPS-1088 | SEVERITY: P3 (Service Unavailable)
REPORTED BY: Monitoring Team
TIME: 10:30 AM (Assigned to L1 Day Shift)
SUMMARY: New monitoring dashboard service cannot be accessed from the network.
DESCRIPTION:
A junior administrator installed a new service (listening on port 8080) 
on one of the application nodes as part of a pilot. The service appears 
to be running (`systemctl status` shows "active"), but when attempting 
to connect from any other host, the connection times out or is refused.

CUSTOMER IMPACT:
The monitoring team cannot access the dashboard, delaying the pilot evaluation.

TROUBLESHOOTING STEPS (L1 SOP):
1. Verify the service is listening on the correct interface and port:
   `ss -tlnp | grep 8080`
2. Check if the local firewall (firewalld) allows the port:
   `sudo firewall-cmd --list-all`
3. Verify SELinux is not blocking the service:
   `sudo ausearch -m avc -ts recent`   (look for denied connections)
4. If firewalld is blocking the port, add a permanent rule:
   `sudo firewall-cmd --add-port=8080/tcp --permanent`
   `sudo firewall-cmd --reload`
5. Test connectivity from another node:
   `curl http://<node-ip>:8080`
======================================================================

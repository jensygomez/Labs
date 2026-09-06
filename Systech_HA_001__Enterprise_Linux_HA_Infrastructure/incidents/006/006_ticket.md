======================================================================
TICKET ID: OPS-1072 | SEVERITY: P3 (Scheduled Task Failure)
REPORTED BY: Automated Disk Space Alert & Junior DevOps Engineer
TIME: 10:30 AM (Assigned to L1 Day Shift)
SUMMARY: The daily log cleanup cron job is not working on the app nodes.
DESCRIPTION:
The `/var/log/httpd` directory on the application nodes is getting full.
The script `/usr/local/bin/cleanup_old_logs.sh` is scheduled to run 
every night via cron, but it is not deleting old log files.
Context:
Yesterday, a junior developer tried to "optimize" the cleanup script 
to make it run faster. After their changes, the job stopped working.
The cron service itself is running fine, and other cron jobs work.
CUSTOMER IMPACT:
Disk space on app nodes will eventually reach 100%, which will cause 
Apache to crash and drop user traffic.
RESOLUTION WORKFLOW (L1 STANDARD OPERATING PROCEDURE):
1. Verify the symptom:
   - Check disk space: `df -h /var/log`
   - Check old files: `ls -lh /var/log/httpd/`
2. Investigate the Cron Job:
   - Check if the job is scheduled: `cat /etc/cron.d/log_cleanup` or `crontab -l`
   - Check cron logs: `grep CRON /var/log/cron | tail -n 20`
3. Investigate the Script:
   - Read the script: `cat /usr/local/bin/cleanup_old_logs.sh`
   - Run it manually to see the output: `/usr/local/bin/cleanup_old_logs.sh`
4. Find the hidden error:
   - Cron jobs don't show errors on the screen. Where does cron send 
     error output? (Hint: check local mail for the root user).
   - `mail` or `cat /var/spool/mail/root`
5. Identify the root cause and fix it:
   - Why did the "optimization" break the script silently?
   - Fix the script and ensure it runs successfully.
AUTOMATION CHALLENGE:
Write a remediation playbook that fixes the broken script, cleans up 
the fake logs injected by the system, and verifies the cron job works.
======================================================================

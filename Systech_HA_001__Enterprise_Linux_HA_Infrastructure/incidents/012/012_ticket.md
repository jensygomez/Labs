ROLE: Act as a Senior SRE / SysAdmin Mentor.
OBJECTIVE: Guide the L1 engineer (Jensy Gomez, future systems administrator) to resolve the incident described in the ticket below. Foster critical thinking and apply a structured troubleshooting methodology.

CRITICAL RULE: YOU DO NOT KNOW THE ROOT CAUSE OR ANY DECOYS.
You only know what is written in the ticket. You must discover the truth alongside the user based only on the command outputs they provide. Do NOT guess the root cause prematurely. Do NOT reveal that there might be more than one problematic process until the user's own output shows it.

TROUBLESHOOTING METHODOLOGY TO ENFORCE:
1. ISOLATE: Guide the user to identify WHICH app_node is affected (hint: monitoring/load-balancer health data, or direct comparison of response times / load average across app01, app02, app03).
2. DIAGNOSE: Ask the user to inspect the process table on the suspected node with `top`/`htop` and `ps auxf` (or `ps -eo pid,ppid,stat,%cpu,cmd`). Do not let them jump straight to `kill` — first ask them to describe what they see: which PID, which %CPU, what PPID, what STAT column value.
3. DIFFERENTIATE: If the user finds more than one anomalous process, guide them to notice that not all abnormal processes are the same kind of problem. Ask them what the STAT column values mean (e.g., "R" vs "Z"), and whether the same remediation (`kill`) applies to both. Do not tell them zombies can't be killed directly — let them discover it by trying and observing the result, then guide them toward the correct target (the parent).
4. HYPOTHESIZE: Based strictly on the user's command outputs, ask them to investigate WHY a process ended up orphaned (PPID 1) instead of tied to a normal parent/session. Guide them toward checking things like `/opt/scripts`, cron, systemd units, and shell history of relevant users — without naming any specific file or user yourself first.
5. REMEDIATE: Guide them to terminate the correct process(es) using the correct target PID for each case (direct process vs. its parent for a zombie), and to investigate/clean any leftover artifacts they find (misleading scripts, history entries) that are NOT legitimate infrastructure.
6. VERIFY: Ensure they confirm CPU load returns to normal (`top`, `uptime`/load average) and that HTTP response times via the VIP are consistent again across all app_nodes.

INTERACTION RULES:
- Ask ONE guiding question at a time. Wait for the user's response.
- If the user finds a script in `/opt/scripts` that looks like a legitimate maintenance tool, do NOT dismiss it as fake. Instead, guide them to verify whether it's actually scheduled anywhere (cron, systemd timer) or whether its presence alone explains why it's running right now (e.g., "Is there a cron job or systemd timer that would explain why this is executing at this moment? What does `crontab -l` / `systemctl list-timers` show for this user/node?").
- If the user tries `kill -9` on a process in state `Z` and reports it "didn't work" or "nothing changed", do NOT explain why yet — ask them what they know about what a `Z` state actually means in the process lifecycle, and who is responsible for reaping a zombie.
- Praise good troubleshooting steps. Gently correct dead ends by asking probing questions.
- Keep your responses concise and focused on the next actionable step.

[TICKET DATA WILL BE PROVIDED BY THE USER NEXT]

======================================================================
TICKET ID: OPS-1127 | SEVERITY: P3 (Performance Degradation)
REPORTED BY: Monitoring System (Auto-Alert) / Escalated by Priya S. (NOC L1 - EMEA Shift)
TIME: 04:52 AM CEST (Assigned to L1 Day Shift)
SUMMARY: One application node responding extremely slowly - possible runaway process
DESCRIPTION:

Greetings L1 Team,

Our monitoring system triggered a CPU load alert on the application tier
approximately 40 minutes ago. Since then, we've started receiving reports
from the traffic simulation clients (client01-04) of increased response
times and occasional timeouts when their requests happen to land on one
specific backend.

The web application (accessed via VIP 10.10.10.30) is still UP and
serving traffic overall, but behavior is INCONSISTENT depending on which
app_node HAProxy's round-robin sends the request to:

- Some requests complete normally, with typical response times.
- Other requests take noticeably longer than usual, and a few clients
  have reported outright timeouts.
- httpd (Apache) is reported as Active/Running on all three app_nodes -
  this does NOT look like a service outage.

BUSINESS IMPACT:
- Intermittent slow responses are affecting user experience.
- Client traffic generators (client01-04) are logging occasional failed
  or delayed transactions.
- If sustained, this will start to affect the batch consolidation window
  for client04, which depends on timely responses from all app_nodes.
- SLA response-time thresholds may be breached if this continues beyond
  the next 90 minutes.

INITIAL TROUBLESHOOTING DONE (BY NOC):
1. Verified Apache status on all app_nodes:
   - app01, app02, app03: httpd is Active (running) on all nodes.
     No crashes, no restarts logged.

2. Checked basic connectivity and HAProxy backend status:
   - HAProxy stats show all three app_nodes as UP/healthy from a
     health-check perspective (the health-check endpoint responds fast
     enough to still pass, even though real request latency is
     inconsistent).

3. Compared load average across the three app_nodes (via monitoring
   dashboard):
   - Two nodes show normal load average for this time of day.
   - ONE node shows a sustained load average significantly higher than
     its baseline, and it has stayed elevated (not a brief spike).

4. NOC does NOT have shell access to run deep diagnostics (process
   inspection, log tailing beyond what monitoring already collects) -
   this is why the ticket is being escalated to L1 with server access.

EXPECTED ACTION FROM L1:
1. Identify which specific app_node has the elevated load (compare
   load average / resource usage across app01, app02, app03).
2. On the affected node, inspect the process table to find what is
   consuming CPU (top, htop, ps auxf or similar).
3. Determine the nature of what you find: is it a single runaway
   process, or could there be more than one anomaly? Pay attention to
   process state, parent PID, and how each one responds to standard
   remediation attempts.
4. Terminate the offending process(es) using the appropriate method for
   each case - not all abnormal processes necessarily respond to the
   same command.
5. Investigate the root cause: why did this process end up running
   unsupervised on this node in the first place? Check for leftover
   scripts, scheduled jobs, or shell history that might explain how it
   was started.
6. Clean up any leftover artifacts you find that are not legitimate
   infrastructure (scripts, history entries, etc.) - use judgment to
   distinguish real maintenance tooling from anything suspicious.
7. Verify that load returns to normal and that response times via the
   VIP (10.10.10.30) are consistent again across all three app_nodes.
8. Provide a Root Cause Analysis (RCA) once resolved, including WHY the
   process became orphaned/unsupervised and how to prevent recurrence.

Best Regards,
Priya S.
NOC L1 Support | Global IT Services

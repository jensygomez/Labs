# 01 - Ansible & YAML Mechanics (Cross-Cutting)
> **Rule:** This file MUST be read for EVERY incident generation. It contains fundamental Ansible mechanics and YAML pitfalls discovered in this lab.

## [BUG-001] `random` filter re-evaluates on every task
- **Symptom:** When using `{{ groups['app_nodes'] | random }}` in multiple tasks, Ansible selects a *different* random node for each task, causing the injection to scatter across the fleet instead of targeting one specific node.
- **Root Cause:** Jinja2 filters like `random` are not cached by default in Ansible task execution.
- **Fix/Rule:** ALWAYS use `set_fact` with `run_once: true` to evaluate the random selection exactly once, then use `add_host` to create a dynamic group for the subsequent plays.

## [BUG-009] State machine desync with multiple marker files
- **Symptom:** When running an Injection playbook after a Recovery playbook, the Recovery playbook skips execution on the second run because the old `recovery_marker` file was never cleaned up by the Injection playbook.
- **Root Cause:** Using separate physical files for `marker_file`, `state_file`, and `recovery_marker` creates synchronization gaps. The Injection playbook only checks its own marker, ignoring the recovery state.
- **Fix/Rule:** Use a SINGLE `state_file` (JSON) for the entire lifecycle. 
  - Injection checks if `state_file` exists. If it says `"status": "recovered"`, it overwrites it to `"injected"`. 
  - Recovery reads the JSON. If it says `"status": "recovered"` or file is missing, it skips (`end_play`). If `"injected"`, it fixes and updates JSON to `"recovered"`.
  - NEVER use separate physical marker files for injection and recovery states.
- **Discovered in:** INC-001 (Authentication & Identity) - Iterative practice testing.

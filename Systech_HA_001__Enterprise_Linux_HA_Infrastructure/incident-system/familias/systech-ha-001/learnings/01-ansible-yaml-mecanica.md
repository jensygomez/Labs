# 01 - Ansible & YAML Mechanics (Cross-Cutting)
> **Rule:** This file MUST be read for EVERY incident generation. It contains fundamental Ansible mechanics and YAML pitfalls discovered in this lab.

## [BUG-001] `random` filter re-evaluates on every task
- **Symptom:** When using `{{ groups['app_nodes'] | random }}` in multiple tasks, Ansible selects a *different* random node for each task, causing the injection to scatter across the fleet instead of targeting one specific node.
- **Root Cause:** Jinja2 filters like `random` are not cached by default in Ansible task execution.
- **Fix/Rule:** ALWAYS use `set_fact` with `run_once: true` to evaluate the random selection exactly once, then use `add_host` to create a dynamic group for the subsequent plays.

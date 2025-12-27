SLOT: Storage – 05
TOPIC: Resize Logical Volumes and Filesystems

Purpose:
Train the ability to detect inconsistencies between
logical volume size and filesystem capacity.

What this slot MAY include:
- LV extended without filesystem resize
- Filesystem resized but not persistent
- Correct LV size but incorrect mount state

What this slot MUST NOT include:
- Multiple simultaneous failures
- SELinux or permission issues
- Data corruption
- Boot-level failures

Expected mental process:
1. Observe storage layers
2. Compare reported sizes
3. Detect inconsistency
4. Identify correct layer to fix
5. Apply minimal correction
6. Verify and ensure persistence

Success criteria:
- Filesystem reflects full LV capacity
- No data loss
- Configuration survives reboot

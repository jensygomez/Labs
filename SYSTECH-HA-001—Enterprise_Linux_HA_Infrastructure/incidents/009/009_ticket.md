======================================================================
TICKET ID: OPS-1092 | SEVERITY: P2 (Storage / Application Impact)
REPORTED BY: Rajesh K. (NOC L1 - APAC Shift)
TIME: 09:15 AM IST (Assigned to L1 Day Shift)
SUMMARY: Storage filesystem mounted in read-only mode on storage01; web uploads failing.
DESCRIPTION:
Greetings of the day L1 Team,

Kindly find the below incident details requiring your immediate attention. 
We are observing that the application nodes (app01, app02, app03) are 
unable to write any new files to the shared web directory (/var/www/html). 

Upon initial checking from the storage side, it is noticed that the 
filesystem `/exports/webdata` on the central storage node `storage01` 
has been automatically mounted in Read-Only (RO) mode by the kernel. 
The NFS service is running, but clients are receiving "Read-only file system" 
errors when trying to upload documents.

Context:
Last night, the infrastructure team ran some routine storage maintenance 
and there was a brief "transient I/O alert" reported by the hypervisor. 
Since then, the kernel has protected the filesystem by locking it in 
read-only mode to prevent data corruption.

BUSINESS IMPACT:
- Client02 and Client04 traffic simulations are failing to write evidence files.
- End-users cannot upload documents via the web portal.
- If not resolved, the application will throw 500 Internal Server Errors.

INITIAL TROUBLESHOOTING DONE (BY NOC):
1. Checked NFS service on storage01: `systemctl status nfs-server` (Active/Running).
2. Checked mount status on storage01: `findmnt /exports/webdata` (Shows 'ro' flag).
3. Checked kernel logs: `dmesg -T | tail -30` (Shows device-mapper I/O errors and XFS shutdown).
4. Verified network connectivity between app nodes and storage01 is fine.

EXPECTED ACTION FROM L1:
1. Investigate the root cause of the I/O errors in `dmesg` / `journalctl`.
2. Understand why the kernel forced the filesystem into read-only mode.
3. Safely unmount the filesystem, run the necessary filesystem checks/repairs (fsck/xfs_repair).
4. Restore the underlying block device to a healthy state.
5. Remount the filesystem in Read-Write (RW) mode and verify NFS exports are writable.

Please do the needful and revert back with the Root Cause Analysis (RCA) once resolved.

Best Regards,
Rajesh K.
NOC L1 Support | Global IT Services
======================================================================

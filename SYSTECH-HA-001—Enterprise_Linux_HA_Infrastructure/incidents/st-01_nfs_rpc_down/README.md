# 🔐 ST-01 Incident - Instructor Guide (DO NOT SHARE WITH STUDENTS)

## 📚 Incident Overview

**Title:** NFS RPC Connectivity Failure  
**Difficulty:** Mid-Level (P2)  
**Estimated Resolution Time:** 20-35 minutes  
**Primary Skill:** Network File System troubleshooting, service dependency analysis  

---

## 🎯 Learning Objectives

By resolving this incident, the student will demonstrate:

1. **Layered Diagnostic Approach** - Not stopping at the first symptom (Apache 403 ≠ Apache problem)
2. **Log Analysis** - Reading `journalctl`, `dmesg`, and service-specific logs
3. **Dependency Mapping** - Understanding NFS dependencies (rpcbind, mountd, firewalld, SELinux)
4. **False Positive Recognition** - Identifying that:
   - `df -h` hanging ≠ disk failure (it's I/O Wait from NFS timeout)
   - Apache 403 ≠ permission issue (it's because NFS mount is inaccessible)
5. **Network Troubleshooting** - Using `showmount`, `rpcinfo`, `ss`, `firewall-cmd`

---

## 🔧 Root Cause

**What was broken:**
- `nfs-server` service was stopped on `storage01`
- Port 2049/tcp was blocked in firewalld on `storage01`

**Why it matters:**
- App nodes have NFS mounts at `/var/www/html` pointing to `storage01:/mnt/shared_webdata`
- When NFS becomes unavailable, any process trying to access the mount hangs in `D` state
- Apache tries to serve files from `/var/www/html` → hangs → returns 403 or times out
- `df -h` tries to stat all mounted filesystems → hangs on NFS mount

---

## 🕵️ Diagnostic Path (Recommended)

### Step 1: Verify the Symptom (2-3 min)
```bash
# On any app node (app01, app02, or app03)
ssh app01

# Check Apache status
systemctl status httpd

# Check error logs
tail -50 /var/log/httpd/error_log

# Try to access the web content directory
ls -la /var/www/html/  # This will HANG or timeout



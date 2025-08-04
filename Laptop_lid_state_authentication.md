# Laptop lid state authentication

## 🎯 Goal

- **When lid is open** → use **fingerprint authentication**.
- **When lid is closed** → skip fingerprint and **fall back to password**.
- Works across **GDM, console, sudo**, etc.

---

## ✅ Step-by-Step Guide

### 1. 📝 Create a Combined Lid Check Script

Create `/usr/local/bin/lid_check.sh`:

```bash
#!/bin/bash
# Returns 0 if lid is open (allow fingerprint), 1 if closed (skip fingerprint)

LID_STATE_FILE="/proc/acpi/button/lid/LID/state"

# Log for debugging (optional)
echo "$(date): $(cat $LID_STATE_FILE)" >> /tmp/pam_lid_debug.log

if grep -q open "$LID_STATE_FILE"; then
    exit 1  # Lid is open → allow fingerprint
else
    exit 0  # Lid is closed → skip fingerprint
fi
```

Then set permissions:

```bash
sudo chmod 755 /usr/local/bin/lid_check.sh
sudo chown root:root /usr/local/bin/lid_check.sh
```

---

### 2. 🛠️ Modify authentication file

Edit file `/etc/pam.d/common-auth` (For Ubuntu)
Edit file `/etc/pam.d/system-auth` (For Fedora)
Edit the file and replace the top `auth` lines with the following:

```
#[Header]

auth        required                                     pam_env.so
auth        required                                     pam_faildelay.so delay=2000000
# Lid check: if lid is closed, skip fingerprint
auth        [success=1 default=ignore]                   pam_exec.so quiet /usr/local/bin/lid_check.sh
auth        sufficient                                   pam_fprintd.so
auth        sufficient                                   pam_unix.so nullok
auth        required                                     pam_deny.s

[the rest ...]
```

Leave the rest of the file unchanged.

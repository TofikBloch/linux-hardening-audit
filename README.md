# Linux Server Hardening Audit Tool

A Bash script that audits Linux servers for common security misconfigurations
and produces a scored report with PASS/WARN/FAIL results.

Tested on Ubuntu 22.04, Ubuntu 24.04, and Amazon Linux 2023.

## What it does

Checks six security areas and produces a score out of 100:

- **SSH configuration** — root login, password auth, port
- **Firewall status** — supports both UFW (Ubuntu) and firewalld (Amazon Linux)
- **Open ports** — detects unnecessary exposed services
- **Failed login attempts** — reads live auth data to detect brute force attacks
- **Disk usage** — flags volumes above safe thresholds
- **World-writable files** — finds files any user can modify

## How to run it

```bash
# Clone the repo
git clone https://github.com/TofikBloch/linux-hardening-audit
cd linux-hardening-audit

# Run with sudo (required to read SSH config and auth logs)
sudo bash audit.sh
```

## Sample output
=====================================
Linux Server Hardening Audit
Host: ip-172-31-14-72.ap-south-1.compute.internal
Date: Fri Jun  5 11:41:22 UTC 2026
=====================================


>> SSH Security

[PASS] Root login is disabled
[PASS] Password Authentication disabled - key-nased only
[WARN] SSH is on default port 22 - consider changing it

>> Firewall Status 

[PASS] firewalld is active

>> Open Ports

 Currently listening:
    0.0.0.0:22
    [::]:22
[PASS] Low number of open ports (2) - small attack surface

>> Failed Login Attempt

[WARN] 1 failed login attempts today - monitor for brute force

>> Disk Usage

[PASS] Disk / is healthy (21%)
[PASS] Disk /boot/efi is healthy (13%)

>> World-Writable Files

Scanning filesytem...
[PASS] No world-writable files found

=====================================
         AUDIT SUMMARY
=====================================
  PASS: 7
  WARN: 2
  FAIL: 0

  Security Score: 77 / 100
Status: MODERATE - review warning and failures
=====================================

## Real-world findings

While running this script on an AWS EC2 instance, the auth log check revealed
an active brute force attack — 49 connection attempts from a single IP
(144.172.109.224, a rented VPS on RouterHosting LLC) within one hour, all
targeting the root account.

The attack failed because:
- `PermitRootLogin no` was set — root SSH access fully disabled
- `PasswordAuthentication no` — key-based auth only, no passwords to brute force
- The attacker IP was subsequently blocked via a firewalld rich rule

## What I learned

- `sshd_config` on Amazon Linux 2023 is locked to root only (`-rw-------`)
  so the script must be run with `sudo` to read it
- Amazon Linux 2023 does not ship with UFW, iptables, or nftables — it uses
  firewalld, requiring an `elif` branch in the firewall check
- Failed login attempts on AL2023 are in `journalctl -u sshd`, not
  `/var/log/auth.log` which is Ubuntu-specific
- `reject` vs `drop` in firewall rules — reject sends immediate refusal so
  bots move on faster, reducing log noise
- Brute force attacks on public servers start within hours of launch —
  hardening is not optional

## Compatibility

| Check | Ubuntu 22.04 | Ubuntu 24.04 | Amazon Linux 2023 |
|---|---|---|---|
| SSH config | ✓ | ✓ | ✓ (requires sudo) |
| Firewall | UFW | UFW | firewalld |
| Auth logs | /var/log/auth.log | /var/log/auth.log | journalctl |
| Disk usage | ✓ | ✓ | ✓ |
| World-writable | ✓ | ✓ | ✓ |

## Author

Tofik Bloch — [github.com/TofikBloch](https://github.com/TofikBloch)

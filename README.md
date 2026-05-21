# Linux Server Hardening Audit Tool

A Bash script that audits a Linux server for common security misconfigurations.
Checks SSH settings, firewall status, open ports, failed logins, disk usage,
and world-writable files. Outputs color-coded results with a security score.

## Features

- SSH security audit (root login, password auth, port)
- Firewall detection (UFW)
- Open port scanning
- Failed login attempt detection
- Disk usage monitoring
- World-writable file scanning
- Color-coded results (PASS / WARN / FAIL)
- Security score out of 100

## Requirements

- Linux (tested on Ubuntu 22.04 / 24.04)
- Bash
- Run as root for full results (sudo)

## Usage

Clone the repository:
    git clone https://github.com/tofikbloch/linux-hardening-audit.git
    cd linux-hardening-audit

Make executable:
    chmod +x audit.sh

Run:
    sudo ./audit.sh

## Sample Output

    >> SSH Security
    [WARN] PermitRootLogin not set - default may allow root
    [WARN] PasswordAuthentication not set - password login may be allowed
    [WARN] SSH is on default port 22 - consider changing it

    >> Firewall Status
    [PASS] UFW firewall is active

    =====================================
                 AUDIT SUMMARY
    =====================================
      PASS: 4
      WARN: 6
      FAIL: 0
      Security Score: 40 / 100
    Status: POOR - immediate hardening required

## Author

Tofik Bloch
BCA Student | Linux & Cloud Enthusiast
linkedin.com/in/tofikbloch
github.com/tofikbloch

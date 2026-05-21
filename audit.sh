#!/bin/bash

# Linux Server Hardening Audit
# Author : Tofik Bloch

RED='\033[;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}"
echo "====================================="
echo "Linux Server Hardening Audit"
echo "Host: $(hostname)"
echo "Date: $(date)"
echo "====================================="
echo -e "${RESET}"

PASS=0
WARN=0
FAIL=0

pass() {
	echo -e "${GREEN}[PASS]${RESET} $1"
	((PASS++))
}

warn() {
	echo -e "${YELLOW}[WARN]${RESET} $1"
	((WARN++))
}

fail() {
	echo -e "${RED}[FAIL]${RESET} $1"
	((FAIL++))
}

check_ssh() {
	echo ""
	echo -e "${CYAN}>> SSH Security${RESET}"
	echo ""

	local config="/etc/ssh/sshd_config"

	if [[ ! -f "$config" ]]; then
		warn "sshd_config not found"
		return
	fi

	local root_login
	root_login=$(grep -i "^PermitRootLogin" "$config" | awk '{print $2}')

	if [[ "$root_login" == "no" ]]; then
		pass "Root login is disabled"
	elif [ -z "$root_login" ]; then
		warn "PermitRootLogin not set - default may allow root"
	else
		fail "Root login is ENABLED - value; $root_login"
	fi

	local pass_auth
	pass_auth=$(grep -i "^PasswordAuthentication" "$config" | awk '{print $2}')

	if [ "$pass_auth" == "no" ]; then
		pass "Password Authentication disabled - key-nased only"
	elif [[ -z "$pass_auth" ]]; then
		warn "PasswordAuthentication not set - password login may be allowed"
	else
		fail "Password authentication is ENABLED"
	fi

	local ssh_port
	ssh_port=$(grep -i "^Port" "$config" | awk '{print $2}')

	if [[ -z "$ssh_port"  || "$ssh_port" == "22" ]]; then
		warn "SSH is on default port 22 - consider changing it"
	else
		pass "SSH running on non-default port $ssh_port"
	fi
}

check_firewall() {
	echo ""
	echo -e "${CYAN}>> Firewall Status ${RESET}"
	echo ""

	if command -v ufw &>/dev/null; then
		local status
		status=$(sudo ufw status 2>/dev/null | grep -i "Status:" | awk '{print $2}')
		if [[ "$status" == "active" ]]; then
			pass "UFW firewall is active"
		else
			fail "UFW is installed but NOT active - server is unprotected"
		fi
	else
		fail "UFW not found - no firewall detected"
	fi
}

check_open_ports() {
	echo ""
	echo  -e "${CYAN}>> Open Ports${RESET}"
	echo ""

	local port_count
	port_count=$(ss -tlnp | grep -c LISTEN)

	echo -e " ${CYAN}Currently listening:${RESET}"
	ss -tlnp | grep LISTEN | awk '{print "    " $4}'

	if [[ "$port_count" -le 5 ]]; then
		pass "Low number of open ports ($port_count) - small attack surface"
	elif [[ "$port_count -le 10" ]]; then
		warn "$port_count ports open - review and close unnecessary ones"
	else
		fail "$port_count ports open - high attack surface"
	fi
}

check_failed_logins() {
	echo ""
	echo -e "${CYAN}>> Failed Login Attempt${RESET}"
	echo ""

	local log="/var/log/auth.log"

	if [[ ! -f "$log" ]]; then
		warn "Auth log not found - cannot check failed  logins"
		return
	fi

	local fail_count
	fail_count=$(grep -c "Failed password" "$log" 2>/dev/null)

	if [[ "$fail_count" -eq 0 ]]; then
		pass "No Failed login attempts found"
	elif [[ "$fail_count" -le 20 ]]; then
		warn "$fail_count failed login attempts - monitor for brute force"
	else
		fail "$fail_count failed logins - possible brute force"
	fi
}

check_disk() {
    echo ""
    echo -e "${CYAN}>> Disk Usage${RESET}"
    echo ""

    while IFS= read -r line; do
        local usage
        local mount
        usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
        mount=$(echo "$line" | awk '{print $6}')

        if [[ "$usage" -ge 90 ]]; then
            fail "Disk $mount is ${usage}% full - CRITICAL"
        elif [[ "$usage" -ge 75 ]]; then
            warn "Disk $mount is ${usage}% full - monitor closely"
        else
            pass "Disk $mount is healthy (${usage}%)"
        fi
    done < <(df -h | grep -v tmpfs | grep -v Filesystem)
}

check_world_writable() {
	echo ""
	echo -e "${CYAN}>> World-Writable Files${RESET}"
	echo ""

	echo -e "${CYAN}Scanning filesytem...${RESET}"

	local ww_files
	ww_files=$(find / -xdev -type f -perm -o+w \
	! -patch "/proc/*" \
	! -patch "/sys/*" \
	! -patch "/dev/*" \
	2>/dev/null)

	if [[ -z "$ww_files" ]]; then
		pass "No world-writable files found"
	else
		local count
		count=$(echo "ww_files" | grep -c .)
		fail "$count world-writable files found:"
		echo "$ww_files" | head -10 | sed 's/^/    /'
	fi
}

print_summary() {
	echo ""
	echo -e "${CYAN}=====================================${RESET}"
	echo -e "${CYAN}                 AUDIT SUMMARY${RESET}"
	echo -e "${CYAN}=====================================${RESET}"
	echo -e "  ${GREEN}PASS: $PASS${RESET}"
	echo -e "  ${YELLOW}WARN: $WARN${RESET}"
	echo -e "  ${RED}FAIL: $FAIL${RESET}"
	echo ""

	local total=$(( PASS +WARN + FAIL ))
	local score=$(( (PASS * 100) / total ))

	echo -e "  Security Score: ${BOLD}$score / 100${RESET}"

	if [[ "$score" -ge 80 ]]; then
		echo -e "Status: ${GREEN}GOOD - server is reasonably hardened${RESET}"
	elif [[ "$score" -ge 50 ]]; then
                echo -e "Status: ${YELLOW}MODERATE - review warning and failures${RESET}"
	else
                echo -e "Status: ${RED}POOR - immediate hardening required${RESET}"
	fi

	echo -e "${CYAN}====================================="
	echo ""
}



check_ssh
check_firewall
check_open_ports
check_failed_logins
check_disk
check_world_writable
print_summary

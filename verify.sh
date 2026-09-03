#!/usr/bin/env bash
set -Eeuo pipefail

fail=0

pass() {
    printf '[PASS] %s\n' "$1"
}

fail_check() {
    printf '[FAIL] %s\n' "$1"
    fail=1
}

echo "========================================"
echo " Asterisk Deployment Verification"
echo "========================================"

EXPECTED_VERSION="22.10.1"

if asterisk -rx "core show version" 2>/dev/null | grep -q "Asterisk ${EXPECTED_VERSION}"; then
    pass "Asterisk ${EXPECTED_VERSION}"
else
    fail_check "Asterisk ${EXPECTED_VERSION}"
fi

if systemctl is-enabled --quiet asterisk 2>/dev/null; then
    pass "systemd enabled"
else
    fail_check "systemd enabled"
fi

if systemctl is-active --quiet asterisk 2>/dev/null; then
    pass "Asterisk service active"
else
    fail_check "Asterisk service active"
fi

if asterisk -rx "module show like pjsip" 2>/dev/null \
    | grep -q 'chan_pjsip.so'; then
    pass "PJSIP channel driver"
else
    fail_check "PJSIP channel driver"
fi

if asterisk -rx "pjsip show transports" 2>/dev/null \
    | grep -q 'transport-udp'; then
    pass "PJSIP UDP transport"
else
    fail_check "PJSIP UDP transport"
fi

if ss -lun 2>/dev/null | grep -q ':5060'; then
    pass "UDP 5060 listening"
else
    fail_check "UDP 5060 listening"
fi

if [[ "$(getenforce 2>/dev/null || true)" == "Enforcing" ]]; then
    pass "SELinux Enforcing"
else
    fail_check "SELinux Enforcing"
fi

if semodule -l 2>/dev/null | grep -q '^asterisk_local_net$'; then
    pass "Asterisk local SELinux module"
else
    fail_check "Asterisk local SELinux module"
fi

if [[ -f /etc/asterisk/stasis.conf ]]; then
    pass "stasis.conf exists"
else
    fail_check "stasis.conf exists"
fi

if [[ -f /etc/asterisk/pjsip.conf ]]; then
    pass "pjsip.conf exists"
else
    fail_check "pjsip.conf exists"
fi

if [[ -f /etc/asterisk/extensions.conf ]]; then
    pass "extensions.conf exists"
else
    fail_check "extensions.conf exists"
fi

if asterisk -rx "dialplan show 600@default" 2>/dev/null \
    | grep -q '600'; then
    pass "Echo extension 600"
else
    fail_check "Echo extension 600"
fi

if journalctl -u asterisk --since "2 minutes ago" --no-pager 2>/dev/null \
    | grep -iE 'ERROR|WARNING|failed|Unable to load' \
    | grep -v 'Stopping Asterisk' \
    | grep -v 'Stopped Asterisk' \
    | grep -q .; then
    fail_check "No recent startup ERROR/WARNING"
else
    pass "No recent startup ERROR/WARNING"
fi

if ausearch -m AVC -ts recent -c asterisk -i 2>/dev/null \
    | grep -q 'name=net'; then
    fail_check "No recent Asterisk /proc/sys/net AVC"
else
    pass "No recent Asterisk /proc/sys/net AVC"
fi

echo
if [[ "$fail" -eq 0 ]]; then
    echo "========================================"
    echo " VERIFICATION: PASS"
    echo "========================================"
else
    echo "========================================"
    echo " VERIFICATION: FAIL"
    echo "========================================"
    exit 1
fi

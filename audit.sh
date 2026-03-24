#!/bin/bash
# ============================================================
# macOS Security Audit Script
# Author: Ed (Worldtraveler247)
# Mode: READ-ONLY — no changes made to your system
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

PASS=0
WARN=0
FAIL=0
TOTAL=0

# ---- Helpers ----

pass() {
    echo -e "  ${GREEN}✅ PASS${NC} — $1"
    ((PASS++)); ((TOTAL++))
}

warn() {
    echo -e "  ${YELLOW}⚠️  WARN${NC} — $1"
    ((WARN++)); ((TOTAL++))
}

fail() {
    echo -e "  ${RED}❌ FAIL${NC} — $1"
    ((FAIL++)); ((TOTAL++))
}

section() {
    echo ""
    echo -e "${BOLD}${BLUE}▶ $1${NC}"
    echo "  ─────────────────────────────────────"
}

# ---- Header ----

clear
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       macOS Security Audit — Worldtraveler247 ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║  Mode: READ-ONLY (no changes will be made)   ║${NC}"
echo -e "${BOLD}║  Date: $(date '+%Y-%m-%d %H:%M:%S')                   ║${NC}"
echo -e "${BOLD}║  Host: $(hostname -s)                              ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ---- 1. Firewall ----

section "Firewall"

fw_status=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null)
if echo "$fw_status" | grep -q "enabled"; then
    pass "Firewall is enabled"
else
    fail "Firewall is DISABLED — enable in System Settings > Network > Firewall"
fi

fw_stealth=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null)
if echo "$fw_stealth" | grep -q "enabled"; then
    pass "Stealth mode is enabled (hides Mac from network scans)"
else
    warn "Stealth mode is disabled — recommended to enable"
fi

# ---- 2. FileVault (Disk Encryption) ----

section "FileVault Disk Encryption"

fv_status=$(fdesetup status 2>/dev/null)
if echo "$fv_status" | grep -q "FileVault is On"; then
    pass "FileVault is ON — disk is encrypted"
else
    fail "FileVault is OFF — your disk is unencrypted. Enable in System Settings > Privacy & Security"
fi

# ---- 3. Screen Lock ----

section "Screen Lock & Auto-Lock"

lock_delay=$(osascript -e 'tell application "System Events" to get require password to wake of security preferences' 2>/dev/null)
if [ "$lock_delay" = "true" ]; then
    pass "Password required after sleep/screensaver"
else
    fail "Password NOT required after sleep — enable in System Settings > Lock Screen"
fi

screensaver_delay=$(defaults -currentHost read com.apple.screensaver idleTime 2>/dev/null)
if [ -n "$screensaver_delay" ] && [ "$screensaver_delay" -le 300 ] 2>/dev/null; then
    pass "Screensaver activates within 5 minutes (${screensaver_delay}s)"
elif [ -n "$screensaver_delay" ] && [ "$screensaver_delay" -le 600 ] 2>/dev/null; then
    warn "Screensaver delay is ${screensaver_delay}s — recommend 300s or less"
else
    warn "Could not determine screensaver delay — verify in System Settings > Lock Screen"
fi

# ---- 4. System Integrity Protection (SIP) ----

section "System Integrity Protection (SIP)"

sip_status=$(csrutil status 2>/dev/null)
if echo "$sip_status" | grep -q "enabled"; then
    pass "SIP is enabled — system files are protected"
else
    fail "SIP is DISABLED — system is vulnerable to rootkit attacks"
fi

# ---- 5. Gatekeeper ----

section "Gatekeeper (App Security)"

gk_status=$(spctl --status 2>/dev/null)
if echo "$gk_status" | grep -q "assessments enabled"; then
    pass "Gatekeeper is enabled — blocks unverified apps"
else
    fail "Gatekeeper is DISABLED — Mac will run apps from anywhere"
fi

# ---- 6. Remote Login (SSH) ----

section "Remote Login & Sharing Services"

ssh_status=$(systemsetup -getremotelogin 2>/dev/null)
if echo "$ssh_status" | grep -q "Off"; then
    pass "Remote Login (SSH) is disabled"
else
    warn "Remote Login (SSH) is ENABLED — make sure this is intentional"
fi

# Check Screen Sharing
screen_sharing=$(launchctl list 2>/dev/null | grep -i "screensharing")
if [ -z "$screen_sharing" ]; then
    pass "Screen Sharing is disabled"
else
    warn "Screen Sharing appears to be active — verify in System Settings > General > Sharing"
fi

# Check File Sharing
file_sharing=$(launchctl list 2>/dev/null | grep -i "AppleFileServer\|smbd")
if [ -z "$file_sharing" ]; then
    pass "File Sharing is disabled"
else
    warn "File Sharing appears active — verify in System Settings > General > Sharing"
fi

# ---- 7. Automatic Updates ----

section "Automatic Security Updates"

auto_update=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled 2>/dev/null)
if [ "$auto_update" = "1" ]; then
    pass "Automatic update checks are enabled"
else
    warn "Automatic update checks are DISABLED — enable in System Settings > General > Software Update"
fi

auto_security=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall 2>/dev/null)
if [ "$auto_security" = "1" ]; then
    pass "Automatic security data updates enabled"
else
    warn "Automatic security data updates DISABLED — recommended to enable"
fi

# ---- 8. Guest Account ----

section "Guest Account"

guest_status=$(defaults read /Library/Preferences/com.apple.loginwindow GuestEnabled 2>/dev/null)
if [ "$guest_status" = "0" ] || [ -z "$guest_status" ]; then
    pass "Guest account is disabled"
else
    fail "Guest account is ENABLED — disable in System Settings > Users & Groups"
fi

# ---- 9. macOS Version ----

section "macOS Version"

os_version=$(sw_vers -productVersion 2>/dev/null)
os_major=$(echo "$os_version" | cut -d. -f1)
echo -e "  ℹ️  macOS version: ${BOLD}$os_version${NC}"
if [ "$os_major" -ge 14 ] 2>/dev/null; then
    pass "Running a recent macOS version ($os_version)"
elif [ "$os_major" -ge 13 ] 2>/dev/null; then
    warn "macOS $os_version — consider updating to the latest release"
else
    fail "macOS $os_version is outdated — update as soon as possible"
fi

# ---- 10. Open Ports ----

section "Listening Network Ports"

echo -e "  ℹ️  Checking for open listening ports..."
open_ports=$(netstat -an 2>/dev/null | grep LISTEN | grep -v "127.0.0.1\|::1" | awk '{print $4}' | sort -u)
if [ -z "$open_ports" ]; then
    pass "No externally exposed listening ports found"
else
    warn "The following ports are listening on external interfaces — review each one:"
    echo "$open_ports" | while read -r port; do
        echo -e "       ${YELLOW}→ $port${NC}"
    done
fi

# ---- Summary ----

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║                 AUDIT SUMMARY                ║${NC}"
echo -e "${BOLD}╠══════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}║  Total checks : $TOTAL                               ║${NC}"
echo -e "${BOLD}║  ${GREEN}✅ PASS        : $PASS${NC}${BOLD}                               ║${NC}"
echo -e "${BOLD}║  ${YELLOW}⚠️  WARN        : $WARN${NC}${BOLD}                               ║${NC}"
echo -e "${BOLD}║  ${RED}❌ FAIL        : $FAIL${NC}${BOLD}                               ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════╝${NC}"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}${BOLD}Action needed: $FAIL critical issue(s) found. Review FAIL items above.${NC}"
elif [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}${BOLD}Good shape, but $WARN item(s) worth reviewing. See WARN items above.${NC}"
else
    echo -e "${GREEN}${BOLD}Your Mac passed all checks. Well secured! ✅${NC}"
fi

echo ""
echo -e "  ${BLUE}Report generated: $(date)${NC}"
echo ""

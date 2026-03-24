# macOS Security Audit Script

A bash script that audits your macOS system for common security misconfigurations.
Runs in **read-only audit mode** — no changes are made to your system.

## What It Checks
- Firewall status
- FileVault disk encryption
- Screen lock / auto-lock timeout
- Remote login (SSH) status
- Gatekeeper (app security)
- System Integrity Protection (SIP)
- Guest account status
- Automatic security updates
- Sharing services (screen sharing, file sharing, etc.)
- DNS configuration

## Usage
```bash
chmod +x audit.sh
./audit.sh
```

## Output
Each check returns one of:
- ✅ PASS — setting is secure
- ⚠️  WARN — review recommended
- ❌ FAIL — insecure, action needed

## Skills Demonstrated
- Bash scripting
- macOS security hardening
- Security auditing and reporting
- CIS Benchmark awareness

## Author
Ed | Cloud Security Engineer in Progress
GitHub: Worldtraveler247

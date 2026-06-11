# IT Playbook — Windows & M365 First Contact

Concise reference for service desk first responders. Pair with `docs/troubleshooting_checklist.md` for a printable version.

## Quick checks (first 60 seconds)

1. Reboot device (full restart).
2. Confirm network connectivity (Wi‑Fi/Ethernet, intranet reachable).
3. Verify credentials and MFA prompt.
4. Capture exact error text and timestamp.

## Common issues and one-line fixes

| Issue | First fix |
|-------|-----------|
| Outlook not sending/receiving | Check offline mode; re-authenticate; clear cached credentials |
| OneDrive not syncing | Confirm sign-in; check storage; restart OneDrive client |
| Printer offline | Power cycle; check network; reinstall driver if persistent |
| VPN fails | Verify credentials; check client logs; test alternate network |
| Windows Update stuck | Run Update Troubleshooter; schedule restart |

## Runnable helpers in this repo

```powershell
# Safe demo — no admin, fictional ticket text
.\scripts\ps_troubleshooter_helper.ps1 -Action demo

# Real diagnostics zip to %TEMP%
.\scripts\ps_troubleshooter_helper.ps1 -Action quick

# Scan sample folder → CSV + HTML report
.\scripts\file_scanner.ps1

# Full walkthrough
.\scripts\run_demo.ps1
```

## What to capture in a ticket

- User name, device hostname, OS version, exact error text, screenshots, steps tried, incident time.
- Attach: Event Viewer excerpt, OneDrive/VPN logs, printer error page, or diagnostics zip from the helper script.

## Escalation

- Tag Level 2 with reproduction steps, logs, screenshots, and priority.
- Multiple users affected → mark outage and notify on-call lead.

## Useful commands

- `ipconfig /all`
- `ping 8.8.8.8`
- `Test-NetConnection outlook.office365.com -Port 443`
- `sfc /scannow` (elevated, slow)

## SLA guidance

- First response within org SLA hours.
- Provide ETA and next steps; follow up until closed.

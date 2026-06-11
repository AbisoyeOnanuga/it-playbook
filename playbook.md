# IT Playbook — Windows & M365 First Contact

Concise reference for service desk first responders. Pair with [`docs/troubleshooting_checklist.md`](docs/troubleshooting_checklist.md) and [`docs/commands_reference.md`](docs/commands_reference.md).

## Quick checks (first 60 seconds)

1. Reboot device (full restart).
2. Confirm network connectivity (Wi‑Fi/Ethernet, intranet reachable).
3. Verify credentials and MFA prompt.
4. Capture exact error text and timestamp.

## Capture a ticket (helper script)

The script **does not submit tickets** — it creates text and a zip you **paste and attach**.

```powershell
.\scripts\ps_troubleshooter_helper.ps1 `
  -Action quick `
  -TicketUser "jane.smith" `
  -Issue "Outlook not sending since 9am" `
  -CopyToClipboard
```

Then:

1. **Ctrl+V** into your ticket system (Description / Notes).
2. **Attach** the `it_diag_*.zip` path printed at the end.
3. Add a **screenshot** of the error and set **priority**.

Full walkthrough: [`docs/ticket_workflow.md`](docs/ticket_workflow.md)

| Mode | What it does |
|------|----------------|
| `-Action demo` | Fictional data → `examples\sample_ticket.txt` (practice) |
| `-Action quick` | Real diagnostics zip + `ticket_draft.txt` in `%TEMP%` |
| `-Action full` | Quick + Application log + `systeminfo` |
| `-CopyToClipboard` | Copies ticket text when done |
| `-OutTicket ".\tickets\INC-1.txt"` | Saves a second copy to a path you choose |
| `-OpenTicket` | Opens draft in Notepad |

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
# Practice ticket capture (fictional)
.\scripts\ps_troubleshooter_helper.ps1 -Action demo -CopyToClipboard

# Real machine — paste into ticket
.\scripts\ps_troubleshooter_helper.ps1 -Action quick -TicketUser "user" -Issue "summary" -CopyToClipboard

# Folder inventory → CSV + HTML
.\scripts\file_scanner.ps1

# Full walkthrough
.\scripts\run_demo.ps1
```

## Useful commands (quick triage)

Run these in order when networking is suspect. See **[`docs/commands_reference.md`](docs/commands_reference.md)** for the full IT-class list with explainers.

| Command | What it tells you |
|---------|-------------------|
| `hostname` | Computer name for the ticket |
| `whoami` | Logged-in user (domain\user) |
| `ipconfig /all` | IP, DNS, gateway, adapter state |
| `ping 8.8.8.8` | Internet reachability (no DNS) |
| `ping google.com` | Internet + DNS working |
| `ipconfig /flushdns` | Clear bad DNS cache |
| `nslookup google.com` | Is DNS resolving names? |
| `tracert 8.8.8.8` | Where packets stop on the path |
| `netstat -ano` | Open ports and owning process IDs |
| `systeminfo` | OS version, patches, uptime |
| `tasklist` | What is running (find hung apps) |
| `net use` | Mapped drives still connected? |
| `Test-NetConnection outlook.office365.com -Port 443` | Can PC reach M365? |
| `sfc /scannow` | Repair system files (elevated, slow) |

## What to capture in a ticket

- User name, device hostname, OS version, exact error text, screenshots, steps tried, incident time.
- Attach: diagnostics zip from helper script, Event Viewer excerpt, app-specific logs.

## Escalation

- Tag Level 2 with reproduction steps, logs, screenshots, and priority.
- Multiple users affected → mark outage and notify on-call lead.

## SLA guidance

- First response within org SLA hours.
- Provide ETA and next steps; follow up until closed.

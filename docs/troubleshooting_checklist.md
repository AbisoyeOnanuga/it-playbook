# First-Contact Troubleshooting Checklist

Print this page for frontline staff. All examples use fictional users and RFC 5737 demo IP addresses.

---

## Log the ticket (every incident)

```powershell
cd path\to\it-playbook
.\scripts\new_ticket.ps1
```

1. Answer prompts (channel, user, location, category, issue).
2. **Ctrl+V** into help desk ticket.
3. File saved in `tickets\` — attach user screenshot or on-site zip if collected.

Full steps: `playbook.md`

---

## 60-second triage

| Step | Action | Pass? |
|------|--------|-------|
| 1 | Ask user to reboot (full restart, not sleep) | ☐ |
| 2 | Confirm network: Wi‑Fi/Ethernet connected, can browse intranet | ☐ |
| 3 | Verify sign-in + MFA prompt completes | ☐ |
| 4 | Capture **exact** error text or screenshot | ☐ |

---

## Common issues → first fix

| Symptom | First fix | If still broken |
|---------|-----------|-----------------|
| Outlook offline / no send | Toggle **Work Offline** off; re-auth account | Clear cached creds; repair Office |
| OneDrive not syncing | Confirm signed in; check storage quota | Reset OneDrive (`onedrive /reset`) |
| Printer offline | Power-cycle printer; check queue | Reinstall driver; test alternate port |
| VPN won't connect | Re-enter creds; try phone hotspot | Collect VPN client log; escalate |
| Windows Update stuck | Run Update Troubleshooter | Schedule maintenance restart |

---

## What to put in every ticket

```
User:     [display name / UPN]
Device:   [hostname, e.g. DEMO-LTP-042]
OS:       [Windows version]
Issue:    [one sentence]
Error:    [verbatim message]
Tried:    [reboot, network, MFA, …]
When:     [date/time, timezone]
Priority: [P3 default; P2 if multi-user]
```

**From your desk (email/chat ticket):**

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action draft -TicketUser "name" -Issue "summary" -ReportedHostname "USER-PC" -CopyToClipboard
```

**On the user's PC only** (visit / remote):

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action quick -TicketUser "name" -Issue "summary" -CopyToClipboard
```

Do **not** use `-Action quick` on your own PC for someone else's ticket.

See `docs/ticket_workflow.md` for all three scenarios.

---

## Escalation rules

- **Level 2**: Repro steps + logs + screenshots attached; tag appropriate queue.
- **Outage**: ≥3 users OR business-critical app → mark outage, notify on-call lead.
- **Security**: Suspected phish/malware → isolate device, do not reboot, escalate immediately.

---

## Handy commands (elevated CMD/PowerShell)

Full list with explainers: **`docs/commands_reference.md`**

| Command | Purpose |
|---------|---------|
| `hostname` / `whoami` | PC name and logged-in user |
| `ipconfig /all` | IP, DNS, adapter status |
| `ping 8.8.8.8` / `ping google.com` | Internet vs DNS |
| `ipconfig /flushdns` | Clear stale DNS cache |
| `nslookup google.com` | Test name resolution |
| `tracert 8.8.8.8` | Find hop where traffic fails |
| `netstat -ano` | Ports and process IDs |
| `systeminfo` | OS version, patches, uptime |
| `tasklist` / `taskkill /PID n /F` | Find/stop hung processes |
| `net use` | Mapped drives |
| `Test-NetConnection outlook.office365.com -Port 443` | M365 connectivity |
| `sfc /scannow` | System file integrity (slow, elevated) |
| `DISM /Online /Cleanup-Image /RestoreHealth` | Repair Windows image (elevated) |

---

## SLA reminders

- Acknowledge within org first-response window.
- Set expectation: what you did, what happens next, when you'll follow up.
- Close loop with user before resolving ticket.

---

*Generated for [it-playbook](https://github.com/) — MIT license. Sample data only.*

# First-Contact Troubleshooting Checklist

Print this page for frontline staff. All examples use fictional users and RFC 5737 demo IP addresses.

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

Attach diagnostics when escalating:

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action quick
```

---

## Escalation rules

- **Level 2**: Repro steps + logs + screenshots attached; tag appropriate queue.
- **Outage**: ≥3 users OR business-critical app → mark outage, notify on-call lead.
- **Security**: Suspected phish/malware → isolate device, do not reboot, escalate immediately.

---

## Handy commands (elevated CMD/PowerShell)

| Command | Purpose |
|---------|---------|
| `ipconfig /all` | IP, DNS, adapter status |
| `ping 8.8.8.8` | Basic internet reachability |
| `Test-NetConnection outlook.office365.com -Port 443` | M365 connectivity |
| `sfc /scannow` | System file integrity (slow) |

---

## SLA reminders

- Acknowledge within org first-response window.
- Set expectation: what you did, what happens next, when you'll follow up.
- Close loop with user before resolving ticket.

---

*Generated for [it-playbook](https://github.com/) — MIT license. Sample data only.*

# Windows and Microsoft 365 First Contact Troubleshooting

## Quick checks (first 60 seconds)
- Reboot device.
- Confirm network connectivity (Wi‑Fi/Ethernet).
- Verify user credentials and MFA prompt.

## Common issues and one‑line fixes
- Outlook not sending/receiving — check offline mode; re‑authenticate; clear cached credentials.
- OneDrive not syncing — confirm sign‑in; check storage; restart OneDrive client.
- Printer offline — power cycle printer; check network; reinstall driver if persistent.
- VPN fails — verify credentials; check VPN client logs; test alternate network.
- Windows update stuck — run Windows Update Troubleshooter; schedule restart.

## What to capture in a ticket
- User name, device hostname, OS version, exact error text, screenshots, steps already tried, time of incident.
- Attach logs: Event Viewer screenshot, OneDrive sync log, VPN client log, printer error page.

## Escalation
- Tag Level 2 with reproduction steps, logs, screenshots, and ticket priority.
- If multiple users affected, mark as outage and notify on‑call lead.

## Useful commands
- `ipconfig /all`
- `ping 8.8.8.8`
- `sfc /scannow`

## SLA guidance
- First response within org SLA hours.
- Provide ETA and next steps; follow up until closed.

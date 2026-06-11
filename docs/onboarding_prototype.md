# Synthetic HR onboarding checklist (fictional org — Acme Corp demo data)
# Do not use real employee names or credentials in tickets.

## Day 0 — before start date
- [ ] Create Entra ID account (UPN: first.last@acme-demo.example)
- [ ] Assign M365 Business Standard license
- [ ] Add to security groups: All-Staff, VPN-Users
- [ ] Prepare laptop asset tag DEMO-LTP-### 

## Day 1 — first login
- [ ] User completes MFA enrollment (Authenticator app)
- [ ] Outlook profile configured; test send/receive
- [ ] OneDrive Known Folder Move opt-in explained
- [ ] Teams desktop + mobile sign-in verified
- [ ] SharePoint "New hire" site access confirmed

## Day 1 — IT verification (15 min)
- [ ] Run quick diagnostics: `.\scripts\ps_troubleshooter_helper.ps1 -Action quick`
- [ ] Confirm BitLocker recovery key escrowed (demo: record key ID only)
- [ ] Document hostname and serial in asset register

## Escalation triggers
- MFA lockout after 3 failed attempts → Identity team
- Missing license → Service desk lead
- Device not in Autopilot → Imaging team

## Ticket template snippet
```
Onboarding — [First Last]
Start date: YYYY-MM-DD
Device: DEMO-LTP-042
Checks: MFA OK, Outlook OK, OneDrive syncing
Notes: ...
```

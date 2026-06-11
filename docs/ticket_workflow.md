# How to capture a ticket with the troubleshooter helper

The helper does **two things**: collects diagnostic files and writes **ready-to-paste ticket text**. Running it alone does not open your ticketing system — you copy the output in.

---

## Real ticket (on a user's PC or your own)

### 1. Run with the user and issue filled in

Open PowerShell from the repo folder (or pass the full path to the script):

```powershell
cd D:\Documents\vscode\it-playbook

.\scripts\ps_troubleshooter_helper.ps1 `
  -Action quick `
  -TicketUser "jane.smith" `
  -Issue "Outlook not sending mail since this morning"
```

Use `-Action full` for extra logs (Application event log + `systeminfo`).

### 2. Read the paths it prints

When finished, the script shows three paths:

```
=== Done ===
Folder : C:\Users\...\AppData\Local\Temp\it_diag_20260610_143022
Zip    : C:\Users\...\AppData\Local\Temp\it_diag_20260610_143022.zip
Ticket : C:\Users\...\AppData\Local\Temp\it_diag_20260610_143022\ticket_draft.txt
```

| File | Use in ticket |
|------|----------------|
| `ticket_draft.txt` | **Paste into Description / Notes** |
| `*.zip` | **Attach** to ticket (logs for Level 2) |
| Folder | Open if you need one file (e.g. `ipconfig.txt`) |

### 3. Copy ticket text to clipboard (easiest)

Add `-CopyToClipboard` — ticket body is copied when the script finishes:

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action quick -TicketUser "jane.smith" -Issue "VPN won't connect" -CopyToClipboard
```

Then **Ctrl+V** into ServiceNow, Jira, Freshdesk, email, etc.

### 4. Save ticket to a known folder (optional)

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action quick `
  -TicketUser "jane.smith" `
  -Issue "Printer offline" `
  -OutTicket ".\tickets\INC-12345.txt"
```

Creates `tickets\INC-12345.txt` in the repo (or any path you choose).

### 5. Open the draft automatically (optional)

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action quick -TicketUser "j.doe" -Issue "OneDrive sync" -OpenTicket
```

Opens `ticket_draft.txt` in Notepad so you can edit before pasting.

---

## Practice / portfolio demo (no real machine data)

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action demo -TicketUser "j.doe" -Issue "Outlook offline"
```

Writes fictional ticket text to:

`examples\sample_ticket.txt`

Open that file to see what a completed ticket block looks like.

---

## What to add manually (script does not know)

After pasting `ticket_draft.txt`, add:

- Exact **error message** (verbatim) or screenshot  
- **Steps you tried** (reboot, cleared creds, etc.) — edit the draft lines if needed  
- **Priority** and **queue** per your org  
- **Screenshot** of the error (attach separately)

---

## Workflow diagram

```
User calls/chat
    │
    ▼
Run playbook quick checks (reboot, network, MFA)
    │
    ▼
.\ps_troubleshooter_helper.ps1 -Action quick -TicketUser "..." -Issue "..." -CopyToClipboard
    │
    ├── Paste ticket_draft.txt body → ticketing system Description
    ├── Attach .zip from %TEMP% → ticket Attachments
    └── Add screenshot + priority → Submit / escalate to L2
```

---

## Troubleshooting the script

| Problem | Fix |
|---------|-----|
| "Nothing in my ticket system" | Script only creates files; you must paste/attach them |
| Can't find zip | Look in `%TEMP%` for `it_diag_*.zip` (script prints full path) |
| `Get-NetAdapter` errors | Run on Windows 10/11; network section may be partial on older OS |
| Want sample only | Use `-Action demo` |

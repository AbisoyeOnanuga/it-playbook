# IT Coordinator workflow (first point of contact)

Mapped to a typical internal IT Coordinator role: phone, email, help desk ticketing system, and in-person support across multiple locations.

## One command — no parameters to memorize

```powershell
cd D:\path\to\it-playbook
.\scripts\new_ticket.ps1
```

Or:

```powershell
.\scripts\ps_troubleshooter_helper.ps1
```

The script asks:

1. **Contact channel** — phone, email, ticketing system, in person  
2. **Employee name**  
3. **Location / site**  
4. **Category** — network, M365, VPN, printer, OneDrive/SharePoint, account/MFA, mobile, A/V-VoIP, hardware  
5. **Device type** — desktop, laptop, mobile, printer, A/V  
6. **Issue summary** and error text  
7. **On user's PC now?** — picks draft vs auto-collect automatically  
8. **Priority** — low / normal / high / urgent  

**Output (every time):**

- Text **copied to clipboard** → Ctrl+V into ticketing system  
- File saved under **`tickets\`** with a readable name (not buried in `%TEMP%`)  
- Notepad opens so you can edit before pasting  

---

## Match contact method to tool mode

| How user reached you | You are... | What happens |
|----------------------|------------|--------------|
| **Ticketing system** | At your desk updating the ticket | Interactive → **draft** (user-reported facts) |
| **Email** | Replying / logging a new ticket | Same — **draft** |
| **Phone** | On a call, user describes symptoms | **draft** — ask `hostname`, `ping` results verbally |
| **In person** | At their desk with their laptop | Interactive → **yes on PC** → **quick** collect |
| **On-site hardware** | Repairing desktop/printer | **draft** or **quick** on that device; note category **hardware** / **printer** |

---

## Duty → playbook section

| Job duty | Playbook resource |
|----------|-------------------|
| Windows 11 Pro, patches | `commands_reference.md` — `systeminfo`, Update Troubleshooter |
| Microsoft 365, email | Category **m365**; `Test-NetConnection outlook.office365.com` |
| VPN | Category **vpn**; credentials + client logs |
| Wi-Fi / network | Category **network**; `ipconfig`, `ping` |
| OneDrive / SharePoint | Category **onedrive-sharepoint** |
| AD, password, MFA | Category **account-mfa** — document in ticket; no password in ticket body |
| Mobile setup | Category **mobile** |
| A/V, VoIP | Category **av-voip** — escalate with room/location |
| Printers, peripherals | Category **printer** |
| Track incidents in ticketing system | `new_ticket.ps1` → paste into portal |
| In-person repairs | On-site → **quick** on that PC; attach zip from `tickets\` |

---

## Example: phone call, no internet (you at your desk)

1. Run `.\scripts\new_ticket.ps1`  
2. Choose **Phone**, enter user name and **location**  
3. Category **Network / Wi-Fi**  
4. **Not** on user's PC → draft mode  
5. Ask user: `hostname`, `ping 8.8.8.8` result, Wi-Fi icon  
6. Script finishes → **Ctrl+V** into ticket, set priority  
7. If not fixed: email `user_collect_diagnostics.ps1` for them to run and reply  

---

## Example: in-person at user's desk

1. Run `.\scripts\new_ticket.ps1`  
2. Choose **In person**  
3. When asked **on user's computer?** → **Yes**  
4. Script collects ipconfig/events from **that** PC  
5. Paste ticket + attach zip from `tickets\diag_*.zip`  

---

## Advanced: skip prompts (optional)

```powershell
.\scripts\ps_troubleshooter_helper.ps1 `
  -TicketUser "jane.smith" `
  -Issue "Printer offline" `
  -Channel "in-person" `
  -Location "Building A" `
  -Category printer `
  -DeviceType printer `
  -Priority normal `
  -ReportedHostname "DESK-PRINT-02"
```

Use when you already know all fields — clipboard and `tickets\` still work automatically.

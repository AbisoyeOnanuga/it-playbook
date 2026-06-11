# IT Playbook — Windows & M365 First Contact

For IT Coordinators: phone, email, help desk ticketing system, and in-person support.

---

## How to use this repo (start here)

### Step 1 — Open PowerShell in the repo folder

```powershell
cd D:\Documents\vscode\it-playbook
```

### Step 2 — Run one command (no parameters)

```powershell
.\scripts\new_ticket.ps1
```

### Step 3 — Answer the prompts

The script walks you through each field. Press **Enter** to skip optional items.

| Prompt | What to enter | Example |
|--------|---------------|---------|
| Contact channel | `1` Phone, `2` Email, `3` Ticketing system, `4` In person | `3` |
| Employee name | Who is having the issue | `jane.smith` |
| Site / location | Building or office (optional) | `Main office` |
| Issue category | `1`–`10` (network, M365, VPN, printer, …) | `1` for network |
| Device type | Desktop, laptop, mobile, printer, A/V | `2` laptop |
| Issue summary | One line for the ticket title | `No internet - websites will not load` |
| Error message | Exact text user sees (optional) | `Chrome: No internet` |
| On user's PC now? | `y` only if you are at **their** keyboard | `n` from your desk |
| If `n` (desk/phone) | Hostname, Windows version, symptoms they report | `LAPTOP-JS`, `ping fails` |
| Priority | `1` low → `4` urgent | `2` normal |

### Step 4 — Paste into your ticketing system

When the script finishes:

1. **Ctrl+V** in the ticket **Description** (text is already on your clipboard).
2. Open the saved file in **`tickets\`** if you want to edit first (Notepad opens automatically).
3. Set priority and category in the portal to match what you chose.
4. Attach a **screenshot** from the user if you have one.
5. If you were **on their PC** (`y`), also attach the zip from **`tickets\diag_*.zip`**.

**That is the full workflow.** No `-TicketUser` flags required unless you want to skip prompts later.

---

## Two situations (the script picks for you)

| You are... | Answer at prompt | What the tool does |
|------------|------------------|-------------------|
| At your desk — phone, email, or ticket portal | **No** — not on user's PC | **Draft** ticket from what the user told you. Does **not** scan your computer. |
| In person at the user's machine | **Yes** — on user's PC | **Collects** ipconfig, events, etc. from **that** PC. Zip saved under `tickets\`. |

---

## Walkthrough: phone call, no internet (desk)

1. User calls: *"I have no internet."*
2. Run `.\scripts\new_ticket.ps1`.
3. Choose **Phone** → name → location → **Network** → **Laptop**.
4. Issue: `No internet`.
5. **Not on user's PC** → `n`.
6. Ask them to run `hostname` and `ping 8.8.8.8` — type answers into the prompts.
7. **Ctrl+V** into the ticket. Done.
8. Still broken? Email them `scripts\user_collect_diagnostics.ps1` to run on **their** PC and reply with the zip.

---

## Walkthrough: in person at user's desk

1. Run `.\scripts\new_ticket.ps1` at their machine.
2. Choose **In person** → fill in name, category, issue.
3. **On user's PC?** → **Yes**.
4. Script collects diagnostics from **this** computer.
5. **Ctrl+V** into ticket + attach `tickets\diag_*.zip`.

---

## After the ticket (troubleshooting)

While on a call or at the desk, use [`docs/commands_reference.md`](docs/commands_reference.md):

- No internet: `ipconfig /all`, `ping 8.8.8.8`, `ping google.com`
- M365: `Test-NetConnection outlook.office365.com -Port 443`
- Printer: power-cycle, check queue, `services.msc` → Print Spooler

Full job-duty mapping: [`docs/coordinator_workflow.md`](docs/coordinator_workflow.md).

---

## Issue categories (menu reference)

| # | Category | Examples |
|---|----------|----------|
| 1 | Network / Wi-Fi | No internet, slow Wi-Fi |
| 2 | M365 / email | Outlook, Teams |
| 3 | VPN | Cannot connect |
| 4 | Printer | Offline, queue stuck |
| 5 | OneDrive / SharePoint | Sync, access |
| 6 | Account / MFA | Password, MFA setup |
| 7 | Mobile | Phone setup, apps |
| 8 | A/V / VoIP | Room equipment, phones |
| 9 | Hardware | On-site PC repair |
| 10 | Other | — |

---

## Escalation

Update ticket status, attach evidence from the **affected** PC, tag Level 2 / IT Manager per org policy.

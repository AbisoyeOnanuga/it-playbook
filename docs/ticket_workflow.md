# How to capture a ticket (three real scenarios)

## How to use (default — no parameters)

```powershell
cd path\to\it-playbook
.\scripts\new_ticket.ps1
```

| Step | Action |
|------|--------|
| 1 | Run `new_ticket.ps1` |
| 2 | **Menus:** type number (`1`) or word (`phone`). **Enter** = default. Invalid input re-prompts. |
| 3 | **Text fields:** type answer and Enter (name, location, issue summary) |
| 4 | **On user's PC now?** `n` from desk/phone · `y` only at their keyboard |
| 5 | **Ctrl+V** into help desk ticket (clipboard filled automatically) |
| 6 | Edit in Notepad if needed; file also in `tickets\` |
| 7 | Attach user screenshot; if on-site collect, attach `tickets\diag_*.zip` |

See [`playbook.md`](../playbook.md) for full walkthroughs (phone call, in-person).

---

The helper does **not** guess which PC has the problem. The interactive script picks the right mode from your answer at step 3.

| If you are... | Use | What gets logged |
|---------------|-----|------------------|
| At ticket queue / email / chat (most common) | `-Action draft` | **User-reported** hostname, symptoms — **not your PC** |
| On the user's machine (visit, RDP, Quick Assist) | `-Action quick` | **That PC's** ipconfig, events, network |
| Practicing / portfolio | `-Action demo` | Fictional sample only |

**Wrong:** Run `-Action quick` on your desk PC for 50 different users → every ticket shows **your** hostname. That is useless and misleading.

---

## Scenario A — Async ticket (default)

You work from your own PC. User emailed or opened a portal ticket: *"No internet."*

1. Triage by chat/email using [`commands_reference.md`](commands_reference.md) — ask user to run `ping 8.8.8.8` and tell you the result.
2. Build the ticket from **what they report**:

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action draft `
  -TicketUser "jane.smith" `
  -Issue "No internet - cannot load websites" `
  -ReportedHostname "LAPTOP-JSMITH" `
  -ReportedOs "Windows 11 23H2" `
  -ReportedNetwork "ping 8.8.8.8 fails; ping google.com fails; Wi-Fi icon shows connected" `
  -StepsTried "User rebooted twice; toggled airplane mode" `
  -ErrorText "Browser: No internet connection" `
  -CopyToClipboard -OpenTicket
```

3. Paste into ServiceNow/Jira. Request screenshot.
4. If escalating, send `scripts\user_collect_diagnostics.ps1` — user runs it **on their PC** and replies with the Desktop zip.

---

## Scenario B — You are on the affected PC

Desk visit, or remote session where **you control the user's machine**.

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action quick `
  -TicketUser "jane.smith" `
  -Issue "No internet" `
  -CopyToClipboard
```

The script prints a warning showing which PC it scanned. Confirm it matches the user's hostname.

1. Paste ticket text.
2. Attach `it_diag_*.zip` from the path printed.
3. Add screenshot.

Use `-Action full` for Application log + `systeminfo` when escalating.

---

## Scenario C — User collects logs themselves

When you cannot remote in, attach this to your reply:

`scripts\user_collect_diagnostics.ps1`

User runs it on **their** computer. Zip appears on their Desktop (`support_diagnostics_*.zip`). They email it back. You combine with a `-Action draft` ticket for the narrative.

---

## Practice / demo

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action demo -CopyToClipboard
```

Writes `examples\sample_ticket.txt` with fictional data.

---

## Workflow diagram

```
                    User reports issue
                           |
           +---------------+---------------+
           |               |               |
     You on user's PC   Async ticket    Need logs only
           |               |               |
    -Action quick    -Action draft    user_collect_diagnostics.ps1
    attach zip       paste text       user emails zip back
           |               |               |
           +---------------+---------------+
                           |
                    Escalate to L2 with
                    correct PC + evidence
```

---

## Parameters (draft mode)

| Parameter | Purpose |
|-----------|---------|
| `-TicketUser` | Who reported (affected user) |
| `-Issue` | One-line summary |
| `-ReportedHostname` | User's PC name (ask them: `hostname`) |
| `-ReportedOs` | e.g. Windows 11 — from user or asset register |
| `-ReportedNetwork` | Symptoms, ping results, Wi-Fi status |
| `-ReportedOneDrive` | Only if M365/sync related |
| `-StepsTried` | Multiline string of what was attempted |
| `-ErrorText` | Exact error message |

Blank fields show `[ask user: ...]` so you know what to fill.

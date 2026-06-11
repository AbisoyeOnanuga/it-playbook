# IT Troubleshooting Playbook & Tools

**Practical playbook, PowerShell helpers, and sanitized examples for first-contact Windows and Microsoft 365 troubleshooting.**

[![Demo GIF](demo/demo.gif)](demo/demo.gif)

Turn a one-page service desk checklist into **runnable artifacts**: diagnostic collection, ticket-ready summaries, and a folder inventory with CSV + HTML reporting — all using fictional demo data safe to share on GitHub.

## What's inside

| Path | Purpose |
|------|---------|
| [`playbook.md`](playbook.md) | Concise first-contact troubleshooting guide |
| [`docs/troubleshooting_checklist.md`](docs/troubleshooting_checklist.md) | Printable checklist for frontline staff |
| [`docs/onboarding_prototype.md`](docs/onboarding_prototype.md) | Sample onboarding runbook (fictional Acme Corp) |
| [`scripts/ps_troubleshooter_helper.ps1`](scripts/ps_troubleshooter_helper.ps1) | Collect diagnostics + draft escalation text |
| [`scripts/file_scanner.ps1`](scripts/file_scanner.ps1) | Scan a project tree → CSV + HTML visualization |
| [`scripts/run_demo.ps1`](scripts/run_demo.ps1) | One-command demo workflow |
| [`examples/`](examples/) | Sanitized sample tree, pre-built reports, ticket draft |

## Quick start

Requires **Windows PowerShell 5.1+** or **PowerShell 7+**. No admin needed for demo mode.

```powershell
git clone https://github.com/AbisoyeOnanuga/it-playbook.git
cd it-playbook

# Full demo: sample ticket + file scan + open HTML report
.\scripts\run_demo.ps1
```

### Capture a ticket (most common question)

The helper **creates** ticket text and a zip — you **paste and attach** them in ServiceNow/Jira/etc.

```powershell
.\scripts\ps_troubleshooter_helper.ps1 `
  -Action quick `
  -TicketUser "jane.smith" `
  -Issue "Outlook not sending" `
  -CopyToClipboard
```

1. **Ctrl+V** into ticket Description  
2. **Attach** the `it_diag_*.zip` path printed when the script finishes  
3. Add screenshot + priority  

See [`docs/ticket_workflow.md`](docs/ticket_workflow.md) for the full workflow. Command cheat sheet: [`docs/commands_reference.md`](docs/commands_reference.md).

### Individual scripts

```powershell
# Practice — fictional ticket to examples\sample_ticket.txt
.\scripts\ps_troubleshooter_helper.ps1 -Action demo -CopyToClipboard

# Real diagnostics (zip + ticket_draft.txt under %TEMP%)
.\scripts\ps_troubleshooter_helper.ps1 -Action quick -TicketUser "user" -Issue "summary" -CopyToClipboard

# Scan bundled sample folder (default) or any project path
.\scripts\file_scanner.ps1
.\scripts\file_scanner.ps1 -Root "D:\Projects\SomeShare" -OutCsv ".\out\scan.csv"
```

Open [`examples/demo_visualization.html`](examples/demo_visualization.html) in a browser to view the asset map.

## Demo workflow

1. **Triage** — follow [`playbook.md`](playbook.md) or the printable checklist.
2. **Capture** — run the troubleshooter (`quick` or `demo`).
3. **Inventory** — run `file_scanner.ps1` when cleaning shared drives or project folders.
4. **Escalate** — attach zip + ticket draft; tag Level 2 with repro steps.

Regenerate the README GIF (optional):

```powershell
python scripts/generate_demo_gif.py
```

## Why this exists

- Standardizes first-contact checks so tickets arrive complete at Level 2.
- Shows practical IT coordination skills: documentation, scripting, and safe handling of user data.
- Every example uses **fictional users, hostnames, and RFC 5737 demo IPs** — no real org data.

## Project structure

```
it-playbook/
├── playbook.md
├── docs/
├── scripts/
├── examples/sample_scan_root/   # synthetic files only
├── examples/demo_report.csv
├── examples/demo_visualization.html
└── demo/demo.gif
```

## License

MIT — see [LICENSE](LICENSE).

## Resume blurb

> **IT Troubleshooting Playbook** — Documented Windows/M365 first-contact procedures and shipped PowerShell tooling to collect diagnostics, draft escalation-ready tickets, and visualize folder inventories (CSV + HTML). Includes sanitized demo data, printable checklists, and a one-command demo script for interviews and portfolio review.

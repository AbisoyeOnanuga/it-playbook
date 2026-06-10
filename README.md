# IT Troubleshooting Playbook and Tools

**One line:** Practical playbook, scripts, and examples for first‑contact Windows and Microsoft 365 troubleshooting.

## Purpose
This repo turns a one‑page troubleshooting playbook into runnable artifacts you can use on a laptop to reproduce common fixes, capture diagnostics, and standardize ticket content for escalation.

## Contents
- `playbook.md` — concise troubleshooting checklist and escalation steps.
- `scripts/ps_troubleshoot_helper.ps1` — PowerShell helper for quick diagnostics and log collection.
- `scripts/scan_assets.py` — small Python script to scan a project folder and produce a CSV report and simple HTML visualization.
- `docs/troubleshooting_checklist.pdf` — printable one‑page checklist for frontline staff.
- `demo/demo.gif` — short demo showing the workflow.

## How to use
1. Clone the repo.
2. For PowerShell helper: run `.\scripts\ps_troubleshoot_helper.ps1 -Action quick` in an elevated PowerShell window.
3. For asset scan: `python3 scripts/scan_assets.py --root "C:\path\to\project" --out examples/demo_report.csv`
4. Open `examples/demo_visualization.html` to view the asset map.

## Why this is useful
- Speeds first‑contact resolution by standardizing checks.
- Produces consistent ticket content for Level 2 escalation.
- Demonstrates practical scripting and documentation skills relevant to IT Coordinator duties.

## Demo
See `demo/demo.gif` for a 60–90 second walkthrough.

## License
MIT

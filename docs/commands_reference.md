# Windows & PowerShell Commands Reference

Short explainers for commands commonly taught in IT support courses. Run CMD commands in **Command Prompt** unless noted; PowerShell commands need **PowerShell** or **Terminal**.

**Tip:** Many CMD tools work in PowerShell too (`ipconfig`, `ping`, `systeminfo`).

---

## Network — "Can this PC reach the network and internet?"

| Command | What it does | When to use |
|---------|--------------|-------------|
| `ipconfig` | Shows IPv4, subnet mask, default gateway for each adapter | First check when user has no internet |
| `ipconfig /all` | Full adapter details: MAC, DNS servers, DHCP lease | DNS issues, wrong gateway, duplicate IP clues |
| `ipconfig /release` | Drops current DHCP lease | Stuck or bad IP after network change |
| `ipconfig /renew` | Requests a fresh IP from DHCP | After `/release` or when IP looks wrong |
| `ipconfig /flushdns` | Clears local DNS cache | Site worked before, fails now; after DNS change |
| `ping 8.8.8.8` | Sends test packets to Google DNS (IP only) | Tests internet without DNS |
| `ping google.com` | Tests internet **and** DNS resolution | Name resolves but IP ping fails = routing/firewall |
| `ping -n 4 hostname` | Send only 4 pings (default runs until Ctrl+C) | Quick test without flooding |
| `tracert google.com` | Shows each router hop to destination | Packet loss or timeout mid-path |
| `nslookup google.com` | Queries DNS for a hostname | "Can't find server" / wrong IP for a site |
| `nslookup google.com 8.8.8.8` | Uses specific DNS server (8.8.8.8) | Is it our DNS or the name itself? |
| `netstat -an` | Lists open ports and connections (numbers) | Is something listening? Suspicious connections? |
| `netstat -ano` | Same + **PID** (process ID) per connection | Find which app owns a port |
| `arp -a` | Shows IP-to-MAC mappings on local LAN | Local device not responding on subnet |
| `hostname` | Prints computer name | Ticket hostname field, remote support |
| `Test-NetConnection outlook.office365.com -Port 443` | PowerShell: tests TCP to M365 (PowerShell) | Outlook/Teams sign-in or sync failures |
| `Test-NetConnection 8.8.8.8` | PowerShell: ping + optional port test | Richer output than `ping` in scripts |

---

## Identity & accounts — "Who is logged in?"

| Command | What it does | When to use |
|---------|--------------|-------------|
| `whoami` | Current username (domain\user) | Confirm correct account on shared PC |
| `whoami /groups` | Groups the user belongs to | Access denied — missing group? |
| `whoami /priv` | Privileges (admin rights) on this session | "Run as admin" didn't work? |
| `net user` | Lists local accounts (or one user if named) | Local account lockout, password expiry |
| `net user username` | Details for one local user | Last logon, account disabled |
| `net localgroup administrators` | Who has local admin | Audit who can install software |

---

## System health — "Is Windows itself OK?"

| Command | What it does | When to use |
|---------|--------------|-------------|
| `systeminfo` | OS version, patch level, uptime, memory | Every escalation ticket — baseline facts |
| `winver` | Opens About Windows (GUI) | Quick version check for user on phone |
| `sfc /scannow` | Scans and repairs protected system files | Crashes, odd OS behavior (**elevated**, slow) |
| `DISM /Online /Cleanup-Image /RestoreHealth` | Repairs Windows component store | `sfc` fails or update errors (**elevated**) |
| `chkdsk C:` | Schedules disk check on next reboot | Disk errors, slow boot, file corruption warnings |
| `chkdsk C: /f` | Fix file system errors (may need reboot) | After SMART warnings or chkdsk prompts |
| `tasklist` | Running processes (like Task Manager list) | What's using CPU/RAM; find PID |
| `tasklist /svc` | Processes with Windows services | Which service belongs to which process |
| `taskkill /PID 1234 /F` | Force-stop process by ID | Hung app (**careful** — confirm PID first) |
| `taskkill /IM notepad.exe /F` | Force-stop by image name | Kill known hung program |
| `shutdown /r /t 0` | Restart immediately | Remote reboot after patch (warn user first) |
| `shutdown /s /t 300` | Shutdown in 5 minutes | Maintenance window |
| `Get-ComputerInfo` | PowerShell summary of OS, RAM, BIOS | Scripting; same family as helper script |
| `Get-EventLog -LogName System -Newest 20` | Last 20 System log entries | Blue screen, driver, service failures |

---

## Services & startup — "Is the required service running?"

| Command | What it does | When to use |
|---------|--------------|-------------|
| `services.msc` | Opens Services GUI | Printer spooler, Windows Update, VPN agent |
| `sc query Spooler` | Status of one service (e.g. Print Spooler) | Scripting / quick CLI check |
| `sc query state= all` | Lists all services and states | Find stopped service after boot |
| `net start Spooler` | Starts a service (**elevated**) | Printer queue stuck after spooler crash |
| `net stop Spooler` | Stops a service (**elevated**) | Clear print queue (delete jobs first) |
| `Get-Service Spooler` | PowerShell service status | Same as `sc query` in scripts |
| `msconfig` | Startup and boot options (legacy) | Disable bad startup item (prefer Task Manager) |

---

## Disk & files — "Is there space? Where did files go?"

| Command | What it does | When to use |
|---------|--------------|-------------|
| `dir C:\` | Lists folder contents | Verify path exists |
| `dir /s` | Recursive list (can be huge) | Find large folders (prefer file_scanner.ps1) |
| `wmic logicaldisk get size,freespace,caption` | Free space per drive | One-liner for tickets |
| `Get-PSDrive -PSProvider FileSystem` | PowerShell free/used per drive | Quick disk space in scripts |
| `tree C:\folder /F` | Folder tree with files | Map share layout for documentation |

---

## Shares & printers — "Can we reach the file server or printer?"

| Command | What it does | When to use |
|---------|--------------|-------------|
| `net use` | Lists mapped network drives | Drive letter missing after VPN |
| `net use Z: \\server\share` | Map drive to UNC path | Restore user's mapped drive |
| `net use Z: /delete` | Disconnect mapped drive | Stale credential / wrong share |
| `net view \\server` | Shares visible on a server | Is the file server reachable? |
| `ping printer-hostname` | Test network path to printer | "Printer offline" on network printer |

---

## Remote & session — "Working on someone else's PC"

| Command | What it does | When to use |
|---------|--------------|-------------|
| `mstsc` | Opens Remote Desktop client | Connect to server or user's PC (if allowed) |
| `query user` | Who is logged on (terminal sessions) | Shared kiosk or RDS server |
| `logoff SESSION_ID` | Log off a session (**elevated**, RDS) | Stuck RDS session |

---

## M365 & apps (common first-contact)

| Command / action | What it does | When to use |
|------------------|--------------|-------------|
| `Test-NetConnection outlook.office365.com -Port 443` | Outlook web services reachable | Mail won't sync |
| `Test-NetConnection login.microsoftonline.com -Port 443` | Entra ID / M365 sign-in | Can't sign in to anything M365 |
| `onedrive /reset` | Resets OneDrive client (user data stays in cloud) | Sync stuck, wrong account |
| `%localappdata%\Microsoft\OneDrive\logs` | Folder path (Explorer) | Collect OneDrive logs for ticket |
| Outlook: **Work Offline** toggle | Stops/starts mail send/receive | Classic "not sending" fix |

---

## Quick triage order (copy this habit)

1. `hostname` + `whoami` — who and which PC  
2. `ipconfig /all` — IP, DNS, gateway  
3. `ping 8.8.8.8` then `ping google.com` — internet vs DNS  
4. `systeminfo` — OS/patches for the ticket  
5. Issue-specific: `Test-NetConnection`, `nslookup`, `net use`, services  

Use the helper script to bundle steps 1–4 automatically:

```powershell
.\scripts\ps_troubleshooter_helper.ps1 -Action quick -TicketUser "j.doe" -Issue "No internet after VPN disconnect"
```

See [ticket_workflow.md](ticket_workflow.md) for how to paste results into your ticketing system.

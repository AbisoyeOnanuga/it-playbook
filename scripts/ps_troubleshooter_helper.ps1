<#
.SYNOPSIS
  Collect Windows diagnostics and format a ticket-ready summary for escalation.

.EXAMPLE
  .\ps_troubleshooter_helper.ps1 -Action quick
  .\ps_troubleshooter_helper.ps1 -Action demo
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('quick', 'full', 'demo')]
    [string]$Action = 'quick',

    [Parameter()]
    [string]$TicketUser = 'j.doe',

    [Parameter()]
    [string]$Issue = 'Outlook stuck in offline mode'
)

Set-StrictMode -Version Latest

function Write-Section {
    param([string]$Title, [string[]]$Lines)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    $Lines | ForEach-Object { Write-Host $_ }
}

function Get-NetworkSummary {
    $adapter = Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
        Where-Object Status -eq 'Up' |
        Select-Object -First 1
    if (-not $adapter) { return @('No active physical adapter detected.') }

    $ip = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Select-Object -First 1
    @(
        "Adapter : $($adapter.Name)"
        "Status  : $($adapter.Status)"
        "Link    : $($adapter.LinkSpeed)"
        "IPv4    : $($ip.IPAddress)"
    )
}

function Get-OneDriveSummary {
    $proc = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
    if ($proc) {
        return @('OneDrive process: running', "PID: $($proc.Id)")
    }
    return @('OneDrive process: not running (user may be signed out or client stopped).')
}

function New-TicketBody {
    param([hashtable]$Facts)

    @"
TICKET SUMMARY (auto-generated)
-------------------------------
User/issue : $($Facts.User) - $($Facts.Issue)
Hostname   : $($Facts.Hostname)
OS         : $($Facts.OS)
Collected  : $($Facts.Timestamp)

Network
$($Facts.Network -join "`n")

OneDrive
$($Facts.OneDrive -join "`n")

Steps already tried (from playbook)
- Reboot confirmed / pending
- Network connectivity checked
- MFA / credential refresh attempted if applicable

Attach
- Diagnostics zip (if collected)
- Screenshot of exact error text

Escalation
- Tag Level 2 with reproduction steps and priority.
"@
}

if ($Action -eq 'demo') {
    Write-Host "IT Playbook - troubleshooter demo (no elevation required)" -ForegroundColor Green
    Write-Section 'Sample ticket context' @(
        "User  : $TicketUser (fictional)"
        "Issue : $Issue"
    )
    Write-Section 'Simulated quick checks' @(
        'Network : Wi-Fi connected, ping 8.8.8.8 OK (demo)'
        'Outlook : Work offline toggled OFF (demo fix applied)'
        'OneDrive: Signed in, sync idle (demo)'
    )
    $demoFacts = @{
        User      = $TicketUser
        Issue     = $Issue
        Hostname  = 'DEMO-LTP-042'
        OS        = 'Windows 11 Pro 23H2 (sample)'
        Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Network   = @('Adapter: Wi-Fi | Status: Up | IPv4: 192.0.2.10 (RFC5737 demo)')
        OneDrive  = @('OneDrive process: running (demo)')
    }
    $ticketPath = Join-Path $PSScriptRoot '..\examples\sample_ticket.txt'
    New-TicketBody -Facts $demoFacts | Set-Content -LiteralPath $ticketPath -Encoding UTF8
    Write-Section 'Ticket draft written' @($ticketPath)
    Write-Host ""
    Write-Host "Demo complete. Open examples\sample_ticket.txt for escalation-ready text." -ForegroundColor Green
    return
}

$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$outdir = Join-Path $env:TEMP "it_diag_$timestamp"
New-Item -ItemType Directory -Path $outdir -Force | Out-Null

Write-Host "Collecting diagnostics -> $outdir"

$computerInfo = Get-ComputerInfo -ErrorAction SilentlyContinue
if ($computerInfo) {
    $computerInfo | Out-File (Join-Path $outdir 'computerinfo.txt')
} else {
    "ComputerInfo unavailable on this host." | Out-File (Join-Path $outdir 'computerinfo.txt')
}

ipconfig /all | Out-File (Join-Path $outdir 'ipconfig.txt')

try {
    Get-EventLog -LogName System -Newest 50 -ErrorAction Stop |
        Out-File (Join-Path $outdir 'system_events.txt')
} catch {
    "System event log unavailable: $($_.Exception.Message)" |
        Out-File (Join-Path $outdir 'system_events.txt')
}

Get-OneDriveSummary | Out-File (Join-Path $outdir 'onedrive_status.txt')
Get-NetworkSummary | Out-File (Join-Path $outdir 'network_summary.txt')

if ($Action -eq 'full') {
    Get-EventLog -LogName Application -Newest 50 -ErrorAction SilentlyContinue |
        Out-File (Join-Path $outdir 'application_events.txt')
    systeminfo | Out-File (Join-Path $outdir 'systeminfo.txt')
}

$facts = @{
    User      = $TicketUser
    Issue     = $Issue
    Hostname  = $env:COMPUTERNAME
    OS        = if ($computerInfo) { "$($computerInfo.OsName) $($computerInfo.OsVersion)" } else { 'Unknown' }
    Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Network   = Get-NetworkSummary
    OneDrive  = Get-OneDriveSummary
}

New-TicketBody -Facts $facts | Out-File (Join-Path $outdir 'ticket_draft.txt') -Encoding UTF8

$zip = Join-Path $env:TEMP "it_diag_$timestamp.zip"
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $outdir '*') -DestinationPath $zip

Write-Section 'Done' @(
    "Folder : $outdir"
    "Zip    : $zip"
    "Ticket : $outdir\ticket_draft.txt"
)
Write-Host "Attach the zip and ticket_draft.txt to your service desk ticket." -ForegroundColor Green

<#
.SYNOPSIS
  Collect Windows diagnostics and format a ticket-ready summary for escalation.

.EXAMPLE
  .\ps_troubleshooter_helper.ps1 -Action quick -TicketUser "jane.smith" -Issue "No internet" -CopyToClipboard
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
    [string]$Issue = 'Outlook stuck in offline mode',

    [Parameter()]
    [string]$OutTicket,

    [Parameter()]
    [switch]$CopyToClipboard,

    [Parameter()]
    [switch]$OpenTicket
)

Set-StrictMode -Version Latest

function Write-Section {
    param([string]$Title, [string[]]$Lines)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    $Lines | ForEach-Object { Write-Host $_ }
}

function Write-NextSteps {
    param(
        [string]$TicketPath,
        [string]$ZipPath,
        [switch]$Copied
    )
    Write-Host ""
    Write-Host "NEXT STEPS - put this in your ticketing system:" -ForegroundColor Yellow
    Write-Host "  1. Open ticket_draft.txt (or paste from clipboard)" -ForegroundColor White
    Write-Host "     $TicketPath"
    Write-Host "  2. Copy all text -> paste into ticket Description / Notes" -ForegroundColor White
    Write-Host "  3. Attach the zip file to the ticket" -ForegroundColor White
    Write-Host "     $ZipPath"
    Write-Host "  4. Add screenshot of error + set priority" -ForegroundColor White
    if ($Copied) {
        Write-Host ""
        Write-Host "Ticket text is on your clipboard (Ctrl+V to paste)." -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "Full guide: docs\ticket_workflow.md" -ForegroundColor DarkGray
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

function Publish-TicketDraft {
    param(
        [string]$Body,
        [string]$PrimaryPath,
        [string]$ExtraPath
    )

    $Body | Out-File -LiteralPath $PrimaryPath -Encoding UTF8

    if ($ExtraPath) {
        $extraDir = Split-Path -Parent $ExtraPath
        if ($extraDir -and -not (Test-Path $extraDir)) {
            New-Item -ItemType Directory -Path $extraDir -Force | Out-Null
        }
        $Body | Set-Content -LiteralPath $ExtraPath -Encoding UTF8
    }

    if ($CopyToClipboard) {
        Set-Clipboard -Value $Body
    }

    if ($OpenTicket) {
        Start-Process notepad.exe -ArgumentList $PrimaryPath
    }
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
    $ticketPath = if ($OutTicket) {
        $OutTicket
    } else {
        Join-Path $PSScriptRoot '..\examples\sample_ticket.txt'
    }
    $ticketPath = [System.IO.Path]::GetFullPath($ticketPath)
    $body = New-TicketBody -Facts $demoFacts
    Publish-TicketDraft -Body $body -PrimaryPath $ticketPath
    Write-Section 'Ticket draft written' @($ticketPath)
    Write-Host ""
    Write-Host "Demo complete. Open the file above and copy/paste into a ticket." -ForegroundColor Green
    if ($CopyToClipboard) {
        Write-Host "Ticket text copied to clipboard." -ForegroundColor Green
    }
    return
}

$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$outdir = Join-Path $env:TEMP "it_diag_$timestamp"
New-Item -ItemType Directory -Path $outdir -Force | Out-Null

Write-Host "Collecting diagnostics -> $outdir"
Write-Host "Ticket user: $TicketUser | Issue: $Issue" -ForegroundColor DarkGray

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

$ticketPath = Join-Path $outdir 'ticket_draft.txt'
$body = New-TicketBody -Facts $facts
Publish-TicketDraft -Body $body -PrimaryPath $ticketPath -ExtraPath $OutTicket

$zip = Join-Path $env:TEMP "it_diag_$timestamp.zip"
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $outdir '*') -DestinationPath $zip

Write-Section 'Done' @(
    "Folder : $outdir"
    "Zip    : $zip"
    "Ticket : $ticketPath"
)
if ($OutTicket) {
    Write-Host "Also saved to: $([System.IO.Path]::GetFullPath($OutTicket))" -ForegroundColor DarkGray
}

Write-NextSteps -TicketPath $ticketPath -ZipPath $zip -Copied:$CopyToClipboard

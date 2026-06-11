<#
.SYNOPSIS
  Build help-desk ticket text. Prompts you if you run it with no parameters.

.DESCRIPTION
  Just run:  .\ps_troubleshooter_helper.ps1
  Answers a few questions -> ticket on clipboard + saved under tickets\

  -Action draft  : phone/email/ticket portal from your desk (default)
  -Action quick  : on the user's PC — auto-collect diagnostics
  -Action demo   : practice sample

.EXAMPLE
  .\ps_troubleshooter_helper.ps1
  .\ps_troubleshooter_helper.ps1 -Action quick -TicketUser "jane.smith" -Issue "Printer offline"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('draft', 'quick', 'full', 'demo')]
    [string]$Action = 'draft',

    [Parameter()]
    [string]$TicketUser = '',

    [Parameter()]
    [string]$Issue = '',

    [Parameter()]
    [ValidateSet('', 'phone', 'email', 'ticket', 'in-person')]
    [string]$Channel = '',

    [Parameter()]
    [string]$Location = '',

    [Parameter()]
    [ValidateSet('', 'network', 'm365', 'vpn', 'printer', 'onedrive-sharepoint', 'account-mfa', 'mobile', 'av-voip', 'hardware', 'other')]
    [string]$Category = '',

    [Parameter()]
    [ValidateSet('', 'desktop', 'laptop', 'mobile', 'printer', 'av', 'other')]
    [string]$DeviceType = '',

    [Parameter()]
    [ValidateSet('', 'low', 'normal', 'high', 'urgent')]
    [string]$Priority = '',

    [Parameter()]
    [string]$ReportedHostname = '',

    [Parameter()]
    [string]$ReportedOs = '',

    [Parameter()]
    [string]$ReportedNetwork = '',

    [Parameter()]
    [string]$ReportedOneDrive = '',

    [Parameter()]
    [string]$StepsTried = '',

    [Parameter()]
    [string]$ErrorText = '',

    [Parameter()]
    [string]$OutTicket,

    [Parameter()]
    [switch]$Interactive,

    [Parameter()]
    [switch]$NoClipboard,

    [Parameter()]
    [switch]$NoOpen
)

Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$ticketsDir = Join-Path $repoRoot 'tickets'
$copyToClipboard = -not $NoClipboard
$openTicket = -not $NoOpen

$CategoryLabels = @{
    'network'             = 'Network / Wi-Fi / connectivity'
    'm365'                = 'Microsoft 365 / email / Outlook'
    'vpn'                 = 'VPN'
    'printer'             = 'Printer / peripheral'
    'onedrive-sharepoint' = 'OneDrive / SharePoint'
    'account-mfa'         = 'Account / AD / password / MFA'
    'mobile'              = 'Mobile device'
    'av-voip'             = 'Audio/visual / VoIP'
    'hardware'            = 'Hardware / on-site repair'
    'other'               = 'Other'
}

function Write-Section {
    param([string]$Title, [string[]]$Lines)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    $Lines | ForEach-Object { Write-Host $_ }
}

function Read-OptionalLine {
    param([string]$Prompt, [string]$Default = '')
    $raw = Read-Host $Prompt
    if ([string]::IsNullOrWhiteSpace($raw)) { return $Default }
    return $raw.Trim()
}

function Read-MenuChoice {
    param(
        [string]$Title,
        [hashtable]$Options,
        [hashtable]$Aliases = @{},
        [string]$DefaultKey = ''
    )

    $sortedKeys = $Options.Keys | Sort-Object { if ($_ -match '^\d+$') { [int]$_ } else { 999 } }, { $_ }

    while ($true) {
        Write-Host ""
        Write-Host $Title -ForegroundColor Cyan
        foreach ($key in $sortedKeys) {
            Write-Host "  $key) $($Options[$key])"
        }

        if ($Aliases.Count) {
            Write-Host "  Words accepted: $($Aliases.Keys -join ', ')" -ForegroundColor DarkGray
        }

        $defaultHint = if ($DefaultKey) { " [Enter = $DefaultKey]" } else { '' }
        $pick = Read-Host "Type the number or word$defaultHint"

        if ([string]::IsNullOrWhiteSpace($pick)) {
            if ($DefaultKey) { return $DefaultKey }
            Write-Host "Please enter a choice." -ForegroundColor Yellow
            continue
        }

        $normalized = $pick.Trim().ToLower()

        if ($Options.ContainsKey($normalized)) {
            return $normalized
        }

        if ($Aliases.ContainsKey($normalized)) {
            $mapped = $Aliases[$normalized]
            if ($Options.ContainsKey($mapped)) { return $mapped }
        }

        foreach ($key in $Options.Keys) {
            $label = $Options[$key].ToString().ToLower()
            if ($label -eq $normalized -or $label.StartsWith($normalized) -or $label.Contains($normalized)) {
                return $key
            }
        }

        Write-Host "Not recognized: '$pick'. Type the number (e.g. 1) or a listed word (e.g. phone)." -ForegroundColor Yellow
    }
}

function Invoke-TicketInterview {
    Write-Host ""
    Write-Host "IT Playbook - new ticket (answer a few questions)" -ForegroundColor Green
    Write-Host "Menu questions: type the NUMBER or the WORD (e.g. 1 or phone)." -ForegroundColor DarkGray
    Write-Host "Press Enter on optional fields to skip." -ForegroundColor DarkGray

    $channelKey = Read-MenuChoice -Title 'How did the user contact you?' -Options @{
        '1' = 'Phone'
        '2' = 'Email'
        '3' = 'Help desk ticketing system'
        '4' = 'In person'
    } -Aliases @{
        'phone'     = '1'
        'p'         = '1'
        'email'     = '2'
        'e'         = '2'
        'mail'      = '2'
        'ticket'    = '3'
        'portal'    = '3'
        'helpdesk'  = '3'
        'help desk' = '3'
        'in person' = '4'
        'in-person' = '4'
        'person'    = '4'
        'onsite'    = '4'
        'on-site'   = '4'
    } -DefaultKey '3'
    $channelMap = @{ '1' = 'phone'; '2' = 'email'; '3' = 'ticket'; '4' = 'in-person' }
    $script:Channel = $channelMap[$channelKey]

    $script:TicketUser = Read-Host "Employee name or username (required)"
    while ([string]::IsNullOrWhiteSpace($script:TicketUser)) {
        Write-Host "User name is required." -ForegroundColor Yellow
        $script:TicketUser = Read-Host "Employee name or username"
    }

    $script:Location = Read-OptionalLine "Site / building / floor (e.g. Main office)"

    $categoryKey = Read-MenuChoice -Title 'Issue category' -Options @{
        '1'  = $CategoryLabels['network']
        '2'  = $CategoryLabels['m365']
        '3'  = $CategoryLabels['vpn']
        '4'  = $CategoryLabels['printer']
        '5'  = $CategoryLabels['onedrive-sharepoint']
        '6'  = $CategoryLabels['account-mfa']
        '7'  = $CategoryLabels['mobile']
        '8'  = $CategoryLabels['av-voip']
        '9'  = $CategoryLabels['hardware']
        '10' = $CategoryLabels['other']
    } -Aliases @{
        'network'    = '1'
        'wifi'       = '1'
        'wi-fi'      = '1'
        'internet'   = '1'
        'm365'       = '2'
        'outlook'    = '2'
        'teams'      = '2'
        'vpn'        = '3'
        'printer'    = '4'
        'print'      = '4'
        'onedrive'   = '5'
        'sharepoint' = '5'
        'account'    = '6'
        'mfa'        = '6'
        'password'   = '6'
        'ad'         = '6'
        'mobile'     = '7'
        'av'         = '8'
        'voip'       = '8'
        'audio'      = '8'
        'hardware'   = '9'
        'other'      = '10'
    } -DefaultKey '1'
    $catMap = @{
        '1' = 'network'; '2' = 'm365'; '3' = 'vpn'; '4' = 'printer'
        '5' = 'onedrive-sharepoint'; '6' = 'account-mfa'; '7' = 'mobile'
        '8' = 'av-voip'; '9' = 'hardware'; '10' = 'other'
    }
    $script:Category = $catMap[$categoryKey]

    $deviceKey = Read-MenuChoice -Title 'Device type' -Options @{
        '1' = 'Desktop'
        '2' = 'Laptop'
        '3' = 'Mobile'
        '4' = 'Printer'
        '5' = 'A/V equipment'
        '6' = 'Other'
    } -Aliases @{
        'desktop' = '1'
        'laptop'  = '2'
        'mobile'  = '3'
        'printer' = '4'
        'av'      = '5'
        'other'   = '6'
    } -DefaultKey '2'
    $devMap = @{ '1' = 'desktop'; '2' = 'laptop'; '3' = 'mobile'; '4' = 'printer'; '5' = 'av'; '6' = 'other' }
    $script:DeviceType = $devMap[$deviceKey]

    $script:Issue = Read-Host "One-line summary (e.g. No internet - websites will not load)"
    while ([string]::IsNullOrWhiteSpace($script:Issue)) {
        $script:Issue = Read-Host "Issue summary (required)"
    }

    $script:ErrorText = Read-OptionalLine "Exact error message (if any)"

    $onSite = Read-MenuChoice -Title 'Are you at the user computer right now?' -Options @{
        'y' = 'Yes - collect diagnostics from this PC'
        'n' = 'No - I am at my desk / on the phone'
    } -Aliases @{
        'yes' = 'y'
        'y'   = 'y'
        'no'  = 'n'
        'n'   = 'n'
    } -DefaultKey 'n'
    if ($onSite -eq 'y') {
        $script:Action = 'quick'
        Write-Host 'Using -Action quick (scan THIS machine - must be the user PC).' -ForegroundColor Yellow
    } else {
        $script:Action = 'draft'
        $script:ReportedHostname = Read-OptionalLine 'User PC hostname (ask them to run: hostname)'
        $script:ReportedOs = Read-OptionalLine "Windows version (e.g. Windows 11 Pro)"
        $script:ReportedNetwork = Read-OptionalLine "Symptoms / ping results / Wi-Fi status"
        if ($script:Category -in @('m365', 'onedrive-sharepoint')) {
            $script:ReportedOneDrive = Read-OptionalLine "Outlook / OneDrive / SharePoint symptoms"
        }
        $script:StepsTried = Read-OptionalLine "Steps already tried (reboot, MFA, etc.)"
    }

    $priorityKey = Read-MenuChoice -Title 'Suggested priority' -Options @{
        '1' = 'Low - single user, workaround exists'
        '2' = 'Normal - single user, no workaround'
        '3' = 'High - multiple users or key role blocked'
        '4' = 'Urgent - outage / security'
    } -Aliases @{
        'low'    = '1'
        'normal' = '2'
        'high'   = '3'
        'urgent' = '4'
    } -DefaultKey '2'
    $priMap = @{ '1' = 'low'; '2' = 'normal'; '3' = 'high'; '4' = 'urgent' }
    $script:Priority = $priMap[$priorityKey]
}

function Get-ShouldInterview {
    if ($Interactive) { return $true }
    if ($Action -eq 'demo') { return $false }
    if ([string]::IsNullOrWhiteSpace($TicketUser) -or [string]::IsNullOrWhiteSpace($Issue)) { return $true }
    return $false
}

function Get-SafeFileSlug {
    param([string]$Text, [int]$Max = 40)
    if (-not $Text) { return 'ticket' }
    $slug = ($Text -replace '[^a-zA-Z0-9\-]+', '-').Trim('-').ToLower()
    if ($slug.Length -gt $Max) { $slug = $slug.Substring(0, $Max).Trim('-') }
    if (-not $slug) { return 'ticket' }
    return $slug
}

function Get-DefaultTicketPath {
    param([string]$User, [string]$Summary)
    New-Item -ItemType Directory -Path $ticketsDir -Force | Out-Null
    $userSlug = Get-SafeFileSlug $User 20
    $issueSlug = Get-SafeFileSlug $Summary 30
    Join-Path $ticketsDir "$(Get-Date -Format 'yyyy-MM-dd_HHmm')_${userSlug}_${issueSlug}.txt"
}

function Get-ChannelLabel {
    param([string]$Value)
    switch ($Value) {
        'phone'      { 'Phone' }
        'email'      { 'Email' }
        'ticket'     { 'Help desk ticketing system' }
        'in-person'  { 'In person' }
        default      { if ($Value) { $Value } else { '[not recorded]' } }
    }
}

function Get-PriorityLabel {
    param([string]$Value)
    switch ($Value) {
        'low'     { 'Low' }
        'normal'  { 'Normal' }
        'high'    { 'High' }
        'urgent'  { 'Urgent' }
        default   { if ($Value) { $Value } else { 'Normal (default)' } }
    }
}

function New-TicketBody {
    param([hashtable]$Facts)

    $steps = if ($Facts.StepsTried) {
        $Facts.StepsTried
    } else {
        @(
            '- Reboot confirmed / pending'
            '- First-contact playbook checks completed'
            '- MFA / credential refresh attempted if applicable'
        ) -join "`n"
    }

    $errorBlock = if ($Facts.ErrorText) { "`nError (verbatim)`n$($Facts.ErrorText)`n" } else { '' }
    $catLabel = if ($Facts.Category -and $CategoryLabels.ContainsKey($Facts.Category)) {
        $CategoryLabels[$Facts.Category]
    } else {
        $Facts.Category
    }

    @"
INCIDENT / SERVICE REQUEST
-------------------------------
Contact     : $(Get-ChannelLabel $Facts.Channel)
Location    : $(if ($Facts.Location) { $Facts.Location } else { '[ask user / asset record]' })
Category    : $(if ($catLabel) { $catLabel } else { '[category]' })
Device      : $(if ($Facts.DeviceType) { $Facts.DeviceType } else { '[device type]' })
Priority    : $(Get-PriorityLabel $Facts.Priority)
Data source : $($Facts.DataSource)

User        : $($Facts.User)
Issue       : $($Facts.Issue)
Hostname    : $($Facts.Hostname)
OS          : $($Facts.OS)
Recorded    : $($Facts.Timestamp)
$errorBlock
Symptoms / network
$($Facts.Network -join "`n")

M365 / OneDrive / SharePoint (if relevant)
$($Facts.OneDrive -join "`n")

Steps already tried
$steps

Attachments
$($Facts.Attachments)

Next steps / escalation
- Update ticketing system status and priority per org SLA.
- Tag Level 2 / IT Manager when on-site repair, A/V, or org-wide impact.
- For remote users: send scripts\user_collect_diagnostics.ps1 to run on THEIR PC before network escalations.
"@
}

function Publish-TicketDraft {
    param(
        [string]$Body,
        [string]$PrimaryPath,
        [string]$ExtraPath
    )

    $parent = Split-Path -Parent $PrimaryPath
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $Body | Out-File -LiteralPath $PrimaryPath -Encoding UTF8

    if ($ExtraPath) {
        $extraDir = Split-Path -Parent $ExtraPath
        if ($extraDir -and -not (Test-Path $extraDir)) {
            New-Item -ItemType Directory -Path $extraDir -Force | Out-Null
        }
        $Body | Set-Content -LiteralPath $ExtraPath -Encoding UTF8
    }

    if ($copyToClipboard) {
        Set-Clipboard -Value $Body
    }

    if ($openTicket) {
        Start-Process notepad.exe -ArgumentList $PrimaryPath
    }
}

function Get-Placeholder {
    param([string]$Value, [string]$Label)
    if ($Value) { return $Value }
    return "[ask user: $Label]"
}

function Get-NetworkSummary {
    $adapter = Get-NetAdapter -Physical -ErrorAction SilentlyContinue |
        Where-Object Status -eq 'Up' | Select-Object -First 1
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
    if ($proc) { return @('OneDrive process: running', "PID: $($proc.Id)") }
    return @('OneDrive process: not running.')
}

function Write-DoneBanner {
    param([string]$TicketPath, [string]$ZipPath = '')
    Write-Host ""
    Write-Host "READY FOR TICKETING SYSTEM" -ForegroundColor Green
    Write-Host "  1. Ctrl+V in your help desk ticket (text copied to clipboard)" -ForegroundColor White
    Write-Host "  2. Saved copy: $TicketPath" -ForegroundColor White
    if ($ZipPath) {
        Write-Host "  3. Attach zip: $ZipPath" -ForegroundColor White
    }
    Write-Host ""
}

# --- interview or defaults ---
if (Get-ShouldInterview) {
    if ($Action -ne 'demo') {
        Invoke-TicketInterview
    }
}

# --- demo ---
if ($Action -eq 'demo') {
    $demoFacts = @{
        Channel     = 'ticket'
        Location    = 'Main site (demo)'
        Category    = 'network'
        DeviceType  = 'laptop'
        Priority    = 'normal'
        DataSource  = 'Demo sample (fictional)'
        User        = if ($TicketUser) { $TicketUser } else { 'j.doe' }
        Issue       = if ($Issue) { $Issue } else { 'No internet (demo)' }
        Hostname    = 'DEMO-LTP-042'
        OS          = 'Windows 11 Pro (demo)'
        Timestamp   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Network     = @('ping 8.8.8.8 fails (demo); Wi-Fi connected')
        OneDrive    = @('n/a')
        StepsTried  = '- User rebooted (demo)'
        ErrorText   = 'Browser: No internet (demo)'
        Attachments = '- Screenshot (demo)'
    }
    $ticketPath = if ($OutTicket) { $OutTicket } else { Join-Path $repoRoot 'examples\sample_ticket.txt' }
    Publish-TicketDraft -Body (New-TicketBody -Facts $demoFacts) -PrimaryPath $ticketPath
    Write-DoneBanner -TicketPath $ticketPath
    return
}

# --- draft ---
if ($Action -eq 'draft') {
    $draftFacts = @{
        Channel     = $Channel
        Location    = $Location
        Category    = $Category
        DeviceType  = $DeviceType
        Priority    = $Priority
        DataSource  = 'User-reported (not auto-scanned on tech PC)'
        User        = $TicketUser
        Issue       = $Issue
        Hostname    = Get-Placeholder $ReportedHostname 'hostname on user PC'
        OS          = Get-Placeholder $ReportedOs 'Windows 11 Pro on user PC'
        Timestamp   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        Network     = @(Get-Placeholder $ReportedNetwork 'symptoms / ping / Wi-Fi')
        OneDrive    = @(Get-Placeholder $ReportedOneDrive 'M365 / OneDrive if relevant')
        StepsTried  = $StepsTried
        ErrorText   = $ErrorText
        Attachments = '- User screenshot`n- Optional: user_collect_diagnostics.ps1 on user PC'
    }

    $ticketPath = if ($OutTicket) { $OutTicket } else { Get-DefaultTicketPath $TicketUser $Issue }
    Publish-TicketDraft -Body (New-TicketBody -Facts $draftFacts) -PrimaryPath $ticketPath
    Write-DoneBanner -TicketPath $ticketPath
    return
}

# --- quick / full ---
Write-Host ""
Write-Host "Collecting from THIS PC: $env:COMPUTERNAME" -ForegroundColor Yellow
Write-Host "Confirm this is the user's affected computer." -ForegroundColor Yellow
Write-Host ""

$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$outdir = Join-Path $env:TEMP "it_diag_$timestamp"
New-Item -ItemType Directory -Path $outdir -Force | Out-Null

$computerInfo = Get-ComputerInfo -ErrorAction SilentlyContinue
if ($computerInfo) {
    $computerInfo | Out-File (Join-Path $outdir 'computerinfo.txt')
} else {
    'ComputerInfo unavailable.' | Out-File (Join-Path $outdir 'computerinfo.txt')
}
ipconfig /all | Out-File (Join-Path $outdir 'ipconfig.txt')
try {
    Get-EventLog -LogName System -Newest 50 -ErrorAction Stop | Out-File (Join-Path $outdir 'system_events.txt')
} catch {
    "Event log unavailable: $($_.Exception.Message)" | Out-File (Join-Path $outdir 'system_events.txt')
}
Get-OneDriveSummary | Out-File (Join-Path $outdir 'onedrive_status.txt')
Get-NetworkSummary | Out-File (Join-Path $outdir 'network_summary.txt')
if ($Action -eq 'full') {
    Get-EventLog -LogName Application -Newest 50 -ErrorAction SilentlyContinue | Out-File (Join-Path $outdir 'application_events.txt')
    systeminfo | Out-File (Join-Path $outdir 'systeminfo.txt')
}

$collectFacts = @{
    Channel     = $Channel
    Location    = $Location
    Category    = $Category
    DeviceType  = $DeviceType
    Priority    = $Priority
    DataSource  = "Auto-collected on PC: $env:COMPUTERNAME"
    User        = $TicketUser
    Issue       = $Issue
    Hostname    = $env:COMPUTERNAME
    OS          = if ($computerInfo) { "$($computerInfo.OsName) $($computerInfo.OsVersion)" } else { 'Unknown' }
    Timestamp   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Network     = Get-NetworkSummary
    OneDrive    = Get-OneDriveSummary
    StepsTried  = $StepsTried
    ErrorText   = $ErrorText
    Attachments = "- Diagnostics zip from user PC`n- Screenshot"
}

$ticketPath = if ($OutTicket) { $OutTicket } else { Get-DefaultTicketPath $TicketUser $Issue }
Publish-TicketDraft -Body (New-TicketBody -Facts $collectFacts) -PrimaryPath $ticketPath
Copy-Item -LiteralPath $ticketPath -Destination (Join-Path $outdir 'ticket_draft.txt') -Force

$zip = Join-Path $ticketsDir "diag_${timestamp}_$(Get-SafeFileSlug $TicketUser 15).zip"
New-Item -ItemType Directory -Path $ticketsDir -Force | Out-Null
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $outdir '*') -DestinationPath $zip

Write-DoneBanner -TicketPath $ticketPath -ZipPath $zip

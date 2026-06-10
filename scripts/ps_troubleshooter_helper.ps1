<#
Simple helper: collects basic diagnostics and zips them for attaching to a ticket.
Usage: .\ps_troubleshoot_helper.ps1 -Action quick
#>

param(
  [Parameter(Mandatory=$false)]
  [ValidateSet("quick","full")]
  [string]$Action = "quick"
)

$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$outdir = "$env:TEMP\it_diag_$timestamp"
New-Item -ItemType Directory -Path $outdir | Out-Null

Write-Host "Collecting basic diagnostics to $outdir"

# Basic info
Get-ComputerInfo | Out-File "$outdir\computerinfo.txt"
ipconfig /all | Out-File "$outdir\ipconfig.txt"
Get-EventLog -LogName System -Newest 50 | Out-File "$outdir\system_events.txt"

# OneDrive status
$onedrive = Get-Process -Name OneDrive -ErrorAction SilentlyContinue
if ($onedrive) { "OneDrive running" | Out-File "$outdir\onedrive_status.txt" } else { "OneDrive not running" | Out-File "$outdir\onedrive_status.txt" }

# Zip results
$zip = "$env:TEMP\it_diag_$timestamp.zip"
Compress-Archive -Path $outdir\* -DestinationPath $zip
Write-Host "Diagnostics collected and zipped to $zip"

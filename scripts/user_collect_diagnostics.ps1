<#
.SYNOPSIS
  For END USERS: run on the computer that has the problem, then email the zip to support.

.DESCRIPTION
  IT staff: attach this script to a ticket reply or share via chat.
  User double-clicks or runs in PowerShell; zip lands on their Desktop.

.EXAMPLE
  Right-click -> Run with PowerShell
  Or: powershell -ExecutionPolicy Bypass -File user_collect_diagnostics.ps1
#>

$timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$outdir = Join-Path $env:TEMP "user_diag_$timestamp"
$desktop = [Environment]::GetFolderPath('Desktop')
$zip = Join-Path $desktop "support_diagnostics_$timestamp.zip"

New-Item -ItemType Directory -Path $outdir -Force | Out-Null

"Collected on: $env:COMPUTERNAME" | Out-File (Join-Path $outdir 'readme.txt')
"User: $env:USERNAME" | Out-File (Join-Path $outdir 'username.txt') -Append
"Time: $(Get-Date)" | Out-File (Join-Path $outdir 'username.txt') -Append

ipconfig /all | Out-File (Join-Path $outdir 'ipconfig.txt')

try {
    Get-ComputerInfo -ErrorAction Stop | Out-File (Join-Path $outdir 'computerinfo.txt')
} catch {
    systeminfo | Out-File (Join-Path $outdir 'systeminfo.txt')
}

try {
    Get-EventLog -LogName System -Newest 30 -ErrorAction Stop |
        Out-File (Join-Path $outdir 'system_events.txt')
} catch {
    "Event log unavailable." | Out-File (Join-Path $outdir 'system_events.txt')
}

if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Compress-Archive -Path (Join-Path $outdir '*') -DestinationPath $zip

Write-Host ""
Write-Host "Done. Please email this file to IT support:" -ForegroundColor Green
Write-Host $zip
Write-Host ""
Write-Host "Press Enter to close."
Read-Host | Out-Null

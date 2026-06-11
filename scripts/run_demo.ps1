<#
.SYNOPSIS
  One-command demo: troubleshooter sample ticket + file scan + open HTML report.
#>

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

Write-Host ""
Write-Host "==========================================" -ForegroundColor DarkCyan
Write-Host "  IT Playbook - full demo workflow" -ForegroundColor DarkCyan
Write-Host "==========================================" -ForegroundColor DarkCyan
Write-Host ""

Write-Host "[1/2] Troubleshooter (demo mode)..." -ForegroundColor Yellow
& (Join-Path $PSScriptRoot 'ps_troubleshooter_helper.ps1') -Action demo

Write-Host ""
Write-Host "[2/2] File scanner (sample tree)..." -ForegroundColor Yellow
& (Join-Path $PSScriptRoot 'file_scanner.ps1')

$htmlPath = Join-Path $repoRoot 'examples\demo_visualization.html'
Write-Host ""
Write-Host "Demo artifacts:" -ForegroundColor Green
Write-Host "  examples\sample_ticket.txt"
Write-Host "  examples\demo_report.csv"
Write-Host "  examples\demo_visualization.html"
Write-Host ""
Write-Host "Opening HTML report in default browser..." -ForegroundColor Green
Start-Process $htmlPath

Pop-Location

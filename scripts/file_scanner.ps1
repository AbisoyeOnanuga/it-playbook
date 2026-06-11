<#
.SYNOPSIS
  Scan a folder tree and export a CSV inventory plus a self-contained HTML report.

.DESCRIPTION
  Safe defaults: scans the bundled sample tree unless -Root is supplied.
  Skips common noise (.git, node_modules, $Recycle.Bin). Never scans entire drives.

.EXAMPLE
  .\file_scanner.ps1
  .\file_scanner.ps1 -Root ".\examples\sample_scan_root" -OutCsv ".\examples\demo_report.csv"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Root = (Join-Path $PSScriptRoot "..\examples\sample_scan_root"),

    [Parameter()]
    [string]$OutCsv = (Join-Path $PSScriptRoot "..\examples\demo_report.csv"),

    [Parameter()]
    [string]$OutHtml = (Join-Path $PSScriptRoot "..\examples\demo_visualization.html"),

    [Parameter()]
    [int]$TopN = 25,

    [Parameter()]
    [string[]]$ExcludeDirNames = @('.git', 'node_modules', '$Recycle.Bin', '__pycache__', '.venv')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-ExcludedPath {
    param([string]$Path)
    foreach ($name in $ExcludeDirNames) {
        if ($Path -match [regex]::Escape([IO.Path]::DirectorySeparatorChar + $name + [IO.Path]::DirectorySeparatorChar) `
            -or $Path -match [regex]::Escape([IO.Path]::AltDirectorySeparatorChar + $name + [IO.Path]::AltDirectorySeparatorChar) `
            -or $Path -match "\\$([regex]::Escape($name))$") {
            return $true
        }
    }
    return $false
}

function Get-FileCategory {
    param([string]$Extension)
    switch -Regex ($Extension) {
        '^\.(doc|docx|pdf|txt|md|rtf)$' { return 'Documents' }
        '^\.(xls|xlsx|csv)$'            { return 'Spreadsheets' }
        '^\.(ppt|pptx)$'                 { return 'Presentations' }
        '^\.(jpg|jpeg|png|gif|svg|webp)$' { return 'Images' }
        '^\.(mp4|mov|avi|mkv)$'          { return 'Video' }
        '^\.(zip|7z|tar|gz|rar)$'        { return 'Archives' }
        '^\.(ps1|py|js|ts|json|xml|yaml|yml)$' { return 'Scripts & config' }
        default                          { return 'Other' }
    }
}

function Format-ByteSize {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return '{0:N2} GB' -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return '{0:N2} MB' -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return '{0:N2} KB' -f ($Bytes / 1KB) }
    return "$Bytes B"
}

$Root = (Resolve-Path -LiteralPath $Root).Path
Write-Host "Scanning: $Root"

$files = @()
Get-ChildItem -LiteralPath $Root -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { -not (Test-ExcludedPath $_.FullName) } |
    ForEach-Object {
        $rel = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
        $ext = $_.Extension.ToLowerInvariant()
        $files += [PSCustomObject]@{
            RelativePath = $rel
            Extension    = if ($ext) { $ext } else { '(none)' }
            SizeBytes    = $_.Length
            SizeHuman    = Format-ByteSize $_.Length
            LastWrite    = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            Category     = Get-FileCategory $ext
        }
    }

if (-not $files.Count) {
    Write-Warning "No files found under $Root"
    exit 1
}

$outCsvDir = Split-Path -Parent $OutCsv
if ($outCsvDir -and -not (Test-Path $outCsvDir)) {
    New-Item -ItemType Directory -Path $outCsvDir -Force | Out-Null
}
$files | Export-Csv -LiteralPath $OutCsv -NoTypeInformation -Encoding UTF8

$totalBytes = ($files | Measure-Object -Property SizeBytes -Sum).Sum
$byCategory = $files | Group-Object Category | Sort-Object { ($_.Group | Measure-Object SizeBytes -Sum).Sum } -Descending
$topFiles = $files | Sort-Object SizeBytes -Descending | Select-Object -First $TopN

$htmlRows = ($topFiles | ForEach-Object {
    $pct = if ($totalBytes -gt 0) { [math]::Round(100.0 * $_.SizeBytes / $totalBytes, 1) } else { 0 }
    $safeName = [System.Net.WebUtility]::HtmlEncode($_.RelativePath)
    $safeCat = [System.Net.WebUtility]::HtmlEncode($_.Category)
    @"
    <tr>
      <td class="path">$safeName</td>
      <td>$safeCat</td>
      <td class="num">$($_.SizeHuman)</td>
      <td class="bar-cell"><div class="bar" style="width:${pct}%"></div><span>${pct}%</span></td>
    </tr>
"@
}) -join "`n"

$categoryBars = ($byCategory | ForEach-Object {
    $catBytes = ($_.Group | Measure-Object SizeBytes -Sum).Sum
    $pct = if ($totalBytes -gt 0) { [math]::Round(100.0 * $catBytes / $totalBytes, 1) } else { 0 }
    $safeCat = [System.Net.WebUtility]::HtmlEncode($_.Name)
    $count = $_.Count
    @"
    <div class="cat-row">
      <span class="cat-label">$safeCat ($count files)</span>
      <div class="cat-bar-wrap"><div class="cat-bar" style="width:${pct}%"></div></div>
      <span class="cat-pct">${pct}% | $(Format-ByteSize $catBytes)</span>
    </div>
"@
}) -join "`n"

$scanTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
$safeRoot = [System.Net.WebUtility]::HtmlEncode($Root)
$safeTotal = Format-ByteSize $totalBytes

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>IT Playbook — File Scan Report</title>
  <style>
    :root { --bg:#0f1419; --panel:#1a2332; --text:#e7ecf3; --muted:#8b9cb3; --accent:#3d8bfd; --bar:#2ecc71; }
    * { box-sizing: border-box; }
    body { font-family: "Segoe UI", system-ui, sans-serif; background: var(--bg); color: var(--text); margin: 0; padding: 2rem; line-height: 1.5; }
    h1 { font-size: 1.5rem; margin: 0 0 .25rem; }
    .meta { color: var(--muted); font-size: .9rem; margin-bottom: 1.5rem; }
    section { background: var(--panel); border-radius: 10px; padding: 1.25rem 1.5rem; margin-bottom: 1.25rem; }
    h2 { font-size: 1rem; margin: 0 0 1rem; color: var(--accent); }
    table { width: 100%; border-collapse: collapse; font-size: .85rem; }
    th, td { text-align: left; padding: .45rem .5rem; border-bottom: 1px solid #2a3548; }
    th { color: var(--muted); font-weight: 600; }
    .path { max-width: 420px; word-break: break-all; }
    .num { white-space: nowrap; }
    .bar-cell { min-width: 140px; }
    .bar-cell span { font-size: .75rem; color: var(--muted); margin-left: .35rem; }
    .bar { display: inline-block; height: 8px; background: var(--bar); border-radius: 4px; min-width: 2px; vertical-align: middle; max-width: 80px; }
    .cat-row { display: grid; grid-template-columns: 180px 1fr 120px; gap: .75rem; align-items: center; margin-bottom: .6rem; font-size: .85rem; }
    .cat-bar-wrap { background: #2a3548; border-radius: 4px; height: 10px; overflow: hidden; }
    .cat-bar { height: 100%; background: var(--accent); border-radius: 4px; min-width: 2px; }
    .cat-pct { text-align: right; color: var(--muted); font-size: .8rem; }
    footer { color: var(--muted); font-size: .75rem; margin-top: 1rem; }
  </style>
</head>
<body>
  <h1>File scan report</h1>
  <p class="meta">Root: <code>$safeRoot</code> · $($files.Count) files · $safeTotal · scanned $scanTime</p>

  <section>
    <h2>Storage by category</h2>
    $categoryBars
  </section>

  <section>
    <h2>Top $TopN largest files</h2>
    <table>
      <thead><tr><th>Path</th><th>Category</th><th>Size</th><th>Share</th></tr></thead>
      <tbody>
$htmlRows
      </tbody>
    </table>
  </section>

  <footer>Generated by it-playbook/scripts/file_scanner.ps1 — fictional sample data only.</footer>
</body>
</html>
"@

$outHtmlDir = Split-Path -Parent $OutHtml
if ($outHtmlDir -and -not (Test-Path $outHtmlDir)) {
    New-Item -ItemType Directory -Path $outHtmlDir -Force | Out-Null
}
[System.IO.File]::WriteAllText($OutHtml, $html, [System.Text.UTF8Encoding]::new($false))

Write-Host "Files scanned : $($files.Count)"
Write-Host "Total size    : $safeTotal"
Write-Host "CSV report    : $OutCsv"
Write-Host "HTML report   : $OutHtml"

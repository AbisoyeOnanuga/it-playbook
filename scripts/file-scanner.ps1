# list top 50 largest files on C: and export to CSV
Get-ChildItem -Path C:\ -Recurse -ErrorAction SilentlyContinue |
  Where-Object { -not $_.PSIsContainer } |
  Select-Object FullName, Length |
  Sort-Object Length -Descending |
  Select-Object -First 50 |
  Export-Csv -Path .\examples\largest_files.csv -NoTypeInformation

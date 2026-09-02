$ErrorActionPreference = "Stop"

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $root

# Hash permanent project contracts/source only.
# Runtime evidence is independently hashed by EVIDENCE_CONTRACT.md.
$excludePrefixes = @(
    ".git/",
    "_NEXT_PHASE/",
    "evidence/phases/"
)

$excludeExact = @(
    "ROADMAP_SHA256.json"
)

function Get-RelativePath {
    param([string]$Base, [string]$Full)
    if ($Full.StartsWith($Base, [StringComparison]::OrdinalIgnoreCase)) {
        return $Full.Substring($Base.Length).TrimStart('\', '/')
    }
    return $Full
}

$files = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
    ForEach-Object {
        $rel = (Get-RelativePath -Base $root -Full $_.FullName).Replace("\", "/")
        [PSCustomObject]@{ File = $_; Rel = $rel }
    } |
    Where-Object {
        $rel = $_.Rel
        $blocked = $false
        foreach ($prefix in $excludePrefixes) {
            if ($rel.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
                $blocked = $true
                break
            }
        }
        -not $blocked -and $excludeExact -notcontains $rel
    } |
    Sort-Object Rel

$manifest = [ordered]@{}
foreach ($entry in $files) {
    $manifest[$entry.Rel] = (Get-FileHash -Algorithm SHA256 -LiteralPath $entry.File.FullName).Hash.ToLowerInvariant()
}

$json = $manifest | ConvertTo-Json -Depth 4

# Write without BOM, UTF-8, PowerShell 5.1 compatible.
[System.IO.File]::WriteAllText(
    (Join-Path $root "ROADMAP_SHA256.json"),
    $json + "`n",
    (New-Object System.Text.UTF8Encoding($false))
)

Write-Host "ROADMAP_SHA256.json updated: $($manifest.Count) permanent files" -ForegroundColor Green
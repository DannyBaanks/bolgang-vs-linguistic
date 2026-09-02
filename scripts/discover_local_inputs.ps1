$ErrorActionPreference = "Stop"

Write-Host "`n=== BOLGANG VS LINGUISTIC / LOCAL DISCOVERY ===" -ForegroundColor Cyan

$roots = @(
    "$HOME\Development",
    "$HOME\Projects",
    (Get-Location).Path
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

function Find-NamedThing {
    param(
        [Parameter(Mandatory=$true)][string]$NamePattern
    )

    $hits = @()
    foreach ($root in $roots) {
        Write-Host "`nSearching $root for $NamePattern ..." -ForegroundColor DarkCyan
        try {
            $hits += Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like $NamePattern }
        } catch {
            Write-Warning $_
        }
    }
    $hits | Sort-Object FullName -Unique
}

Write-Host "`n=== Classic Malbolge interpreters ===" -ForegroundColor Yellow
$malbolgeHits = @()
foreach ($root in $roots) {
    try {
        $malbolgeHits += Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match '(?i)malbolge' -or
                $_.DirectoryName -match '(?i)malbolge'
            } |
            Select-Object -First 100
    } catch {}
}
if ($malbolgeHits.Count -eq 0) {
    Write-Host "NONE FOUND -> Classic Malbolge interpreter required for P00." -ForegroundColor Red
} else {
    $malbolgeHits |
        Sort-Object FullName -Unique |
        Select-Object FullName, PSIsContainer, Length, LastWriteTime |
        Format-Table -AutoSize
}

Write-Host "`n=== GitHub Linguist checkout ===" -ForegroundColor Yellow
$linguistHits = @()
foreach ($root in $roots) {
    try {
        $linguistHits += Get-ChildItem -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match '(?i)linguist' -or
                $_.DirectoryName -match '(?i)linguist'
            } |
            Select-Object -First 100
    } catch {}
}
if ($linguistHits.Count -eq 0) {
    Write-Host "NONE FOUND -> GitHub Linguist required for P00." -ForegroundColor Red
} else {
    $linguistHits |
        Sort-Object FullName -Unique |
        Select-Object FullName, PSIsContainer, Length, LastWriteTime |
        Format-Table -AutoSize
}

Write-Host "`n=== SHA256 for directly hashable artifacts ===" -ForegroundColor Yellow
$malbolgeHits | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
    Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName
}

Write-Host "`nDiscovery does NOT prove provenance. Record the selected exact path and hash manifest in P00 evidence." -ForegroundColor Green

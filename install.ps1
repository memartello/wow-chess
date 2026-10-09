param([string]$AddOnsDir = $env:WOW_ADDONS_DIR)

$ErrorActionPreference = 'Stop'

if (-not $AddOnsDir) {
    $foundDirs = @()
    foreach ($base in @(
        [Environment]::GetEnvironmentVariable('ProgramFiles(x86)'),
        $env:ProgramFiles
    )) {
        if ($base) {
            $candidate = Join-Path $base 'World of Warcraft\_classic_beta_\Interface\AddOns'
            if ((Test-Path -LiteralPath $candidate -PathType Container) -and $foundDirs -notcontains $candidate) {
                $foundDirs += $candidate
            }
        }
    }

    if ($foundDirs.Count -ne 1) {
        Write-Error 'Indicá la carpeta Interface\AddOns de _classic_beta_: .\install.ps1 -AddOnsDir "D:\Juegos\World of Warcraft\_classic_beta_\Interface\AddOns"'
        exit 1
    }
    $AddOnsDir = $foundDirs[0]
}

if (-not (Test-Path -LiteralPath $AddOnsDir -PathType Container)) {
    Write-Error "No existe la carpeta de AddOns: $AddOnsDir"
    exit 1
}

$target = Join-Path $AddOnsDir 'WoWChess'
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item -Path (Join-Path $PSScriptRoot 'WoWChess\*') -Destination $target -Recurse -Force
if (-not (Test-Path -LiteralPath (Join-Path $target 'WoWChess_Camelot.toc'))) {
    throw 'No se encontró WoWChess_Camelot.toc después de copiar el addon.'
}
Write-Host "WoW Chess instalado en: $target"

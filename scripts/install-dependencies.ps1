#Requires -Version 5.1
<#
.SYNOPSIS
  Installe les dépendances officielles Qbox / Ox (Windows).
.NOTES
  Exécuter depuis la racine du repo :
    Set-ExecutionPolicy -Scope Process Bypass
    .\scripts\install-dependencies.ps1
#>
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Res = Join-Path $Root "resources"
$Tmp = Join-Path $Root ".tmp-install"

function Ensure-Dir($Path) {
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Clone-OrUpdate([string]$Url, [string]$Dest, [string]$Ref = "main") {
    if (Test-Path (Join-Path $Dest ".git")) {
        Write-Host "[update] $Dest" -ForegroundColor Cyan
        Push-Location $Dest
        try {
            git fetch --depth 1 origin $Ref
            git checkout -q $Ref
            git pull --ff-only origin $Ref 2>$null
        } finally { Pop-Location }
    } else {
        Write-Host "[clone] $Url -> $Dest" -ForegroundColor Green
        if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
        git clone --depth 1 --branch $Ref $Url $Dest
    }
}

function Download-Zip([string]$Url, [string]$ZipPath, [string]$DestDir) {
    Write-Host "[download] $Url" -ForegroundColor Yellow
    Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
    Expand-Archive -Path $ZipPath -DestinationPath $DestDir -Force
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git n'est pas installé. Téléchargez Git for Windows : https://git-scm.com/download/win"
}

Ensure-Dir $Tmp
Ensure-Dir (Join-Path $Res "[ox]")
Ensure-Dir (Join-Path $Res "[qbx]")
Ensure-Dir (Join-Path $Res "[standalone]")
Ensure-Dir (Join-Path $Res "[voice]")

Write-Host "==> Ox / Overextended" -ForegroundColor Magenta
Clone-OrUpdate "https://github.com/overextended/oxmysql.git" (Join-Path $Res "[ox]\oxmysql") "main"
Clone-OrUpdate "https://github.com/overextended/ox_lib.git" (Join-Path $Res "[ox]\ox_lib") "master"
Clone-OrUpdate "https://github.com/overextended/ox_target.git" (Join-Path $Res "[ox]\ox_target") "main"
Clone-OrUpdate "https://github.com/overextended/ox_inventory.git" (Join-Path $Res "[ox]\ox_inventory") "main"
Clone-OrUpdate "https://github.com/overextended/ox_doorlock.git" (Join-Path $Res "[ox]\ox_doorlock") "main"
Clone-OrUpdate "https://github.com/overextended/ox_fuel.git" (Join-Path $Res "[ox]\ox_fuel") "main"

Write-Host "==> Qbox" -ForegroundColor Magenta
$qbx = @(
    "qbx_core","qbx_vehicles","qbx_garages","qbx_vehiclekeys","qbx_management",
    "qbx_properties","qbx_police","qbx_ambulancejob","qbx_medical","qbx_mechanicjob",
    "qbx_taxijob","qbx_hud","qbx_adminmenu","qbx_radialmenu","qbx_smallresources",
    "qbx_spawn","qbx_cityhall","qbx_vehicleshop","qbx_seatbelt"
)
foreach ($name in $qbx) {
    Clone-OrUpdate "https://github.com/Qbox-project/$name.git" (Join-Path $Res "[qbx]\$name") "main"
}

Write-Host "==> Standalone / voice" -ForegroundColor Magenta
Clone-OrUpdate "https://github.com/Bob74/bob74_ipl.git" (Join-Path $Res "[standalone]\bob74_ipl") "master"
Clone-OrUpdate "https://github.com/AvarianKnight/pma-voice.git" (Join-Path $Res "[voice]\pma-voice") "main"

$standalone = Join-Path $Res "[standalone]"
if (-not (Test-Path (Join-Path $standalone "Renewed-Banking"))) {
    $zip = Join-Path $Tmp "Renewed-Banking.zip"
    Download-Zip "https://github.com/Renewed-Scripts/Renewed-Banking/releases/latest/download/Renewed-Banking.zip" $zip $standalone
}
if (-not (Test-Path (Join-Path $standalone "illenium-appearance"))) {
    $zip = Join-Path $Tmp "illenium-appearance.zip"
    Download-Zip "https://github.com/iLLeniumStudios/illenium-appearance/releases/latest/download/illenium-appearance.zip" $zip $standalone
}

Write-Host "==> Build ox_lib / ox_inventory" -ForegroundColor Magenta
if (Get-Command pnpm -ErrorAction SilentlyContinue) {
    Push-Location (Join-Path $Res "[ox]\ox_lib")
    pnpm i; pnpm build
    Pop-Location
    Push-Location (Join-Path $Res "[ox]\ox_inventory")
    pnpm i; pnpm build
    Pop-Location
} else {
    Write-Warning "pnpm absent. Installez Node.js puis: npm i -g pnpm — puis compilez ox_lib et ox_inventory."
}

Write-Host ""
Write-Host "Installation terminée." -ForegroundColor Green
Write-Host "1. Configurez mysql_connection_string dans server.cfg"
Write-Host "2. Importez sql\00_qbox_recipe.sql puis sql\01_rp_custom.sql"
Write-Host "3. Ajoutez votre sv_licenseKey"
Write-Host "4. Guide complet: docs\INSTALL_WINDOWS.md"

# VERBA single-click asset installer: no Python, package manager, or admin required.
# Downloads only explicitly selected, CC0 3D models and Poly Haven PBR maps.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$models = Join-Path $root 'assets\models\cc0'
$photos = Join-Path $root 'assets\textures\real'
New-Item -ItemType Directory -Force -Path $models,$photos | Out-Null
$headers = @{ 'User-Agent' = 'VERBA/1.2 (Powered by Poly Haven; https://polyhaven.com)' }
$failed = @()
$installed = 0
$base = 'https://raw.githubusercontent.com/anshaneja5/skyline-run/main/public/assets/models/'
function Save-Asset([string]$url,[string]$destination,[string]$kind) {
    $temp = "$destination.download"
    try {
        Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing -TimeoutSec 90 -Headers $headers
        $data = [System.IO.File]::ReadAllBytes($temp)
        if ($data.Length -lt 10000) { throw "Incomplete file" }
        if ($kind -eq 'glb' -and [System.Text.Encoding]::ASCII.GetString($data,0,4) -ne 'glTF') { throw 'Not a GLB model' }
        if ($kind -eq 'jpg' -and ($data[0] -ne 255 -or $data[1] -ne 216 -or $data[2] -ne 255)) { throw 'Not a JPEG texture' }
        Move-Item $temp $destination -Force
        Write-Host "Installed: $([IO.Path]::GetFileName($destination))" -ForegroundColor Green
        return $true
    } catch {
        Remove-Item $temp -Force -ErrorAction SilentlyContinue
        Write-Host "FAILED: $url : $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}
Write-Host 'VERBA — real CC0 art installer' -ForegroundColor Cyan
Write-Host 'Fetching Quaternius geometry from GitHub…'
foreach ($name in @('tree1.glb','tree2.glb','tree3.glb','bush.glb')) {
    $destination = Join-Path $models $name
    if ((Test-Path $destination) -and ((Get-Item $destination).Length -gt 10000)) { Write-Host "Already present: $name"; continue }
    if (Save-Asset ($base+$name) $destination 'glb') { $installed++ } else { $failed += $name }
}
Write-Host 'Fetching photographic Poly Haven materials (1K diffuse + normal)…'
$surfaces = @(
    @{ Slot='meadow_ground'; Name='forrest_ground_01' },
    @{ Slot='woodland_ground'; Name='forest_floor' },
    @{ Slot='amber_ground'; Name='forest_floor' },
    @{ Slot='earth_path'; Name='forrest_ground_01' },
    @{ Slot='bark'; Name='bark_brown_01' },
    @{ Slot='cottage_wood'; Name='wood_planks' }
)
$manifest = Join-Path $photos 'VERBA_INSTALLED_CC0.txt'
$previous = @()
if (Test-Path $manifest) { $previous = @(Get-Content $manifest) }
$cache = @{}
foreach ($entry in $surfaces) {
    $slug = $entry.Name
    if (-not $cache.ContainsKey($slug)) {
        try { $cache[$slug] = Invoke-RestMethod -Uri "https://api.polyhaven.com/files/$slug" -Headers $headers -TimeoutSec 30 }
        catch { Write-Host "API error on $slug : $_" -ForegroundColor Yellow; $failed += $slug; continue }
    }
    foreach ($map in @(@('Diffuse','diffuse'),@('nor_gl','normal'))) {
        $channel = $map[0]; $suffix = $map[1]
        $key = "$($entry.Slot)_$suffix"
        $destination = Join-Path $photos "$key.jpg"
        if ($previous -contains "$key=$slug" -and (Test-Path $destination) -and ((Get-Item $destination).Length -gt 10000)) {
            Write-Host "Already installed: $key"; continue
        }
        try {
            $source = $cache[$slug].PSObject.Properties[$channel].Value
            if ($null -eq $source) { throw "Missing $channel" }
            $res = $source.PSObject.Properties['1k'].Value
            if ($null -eq $res) { throw 'Missing 1K size' }
            $format = $res.PSObject.Properties['jpg'].Value
            if ($null -eq $format) { throw 'Missing JPG map' }
            if (Save-Asset $format.url $destination 'jpg') {
                $installed++
                $previous = @($previous | Where-Object { $_ -notlike "$key=*" }) + @("$key=$slug")
                Set-Content -Path $manifest -Value $previous
            } else { $failed += $key }
        } catch { Write-Host "FAILED map $key : $_" -ForegroundColor Yellow; $failed += $key }
    }
}
Write-Host "`nInstalled files: $installed. Errors: $($failed.Count)" -ForegroundColor Cyan
if ($failed.Count -gt 0) { Write-Host 'You can run this installer again. Failed items retain the prior bundled art.' -ForegroundColor Yellow }
Write-Host 'Next: open VERBA project.godot in Godot and click Edit for asset import.' -ForegroundColor Green

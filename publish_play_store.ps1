# publish_play_store.ps1
# This script builds the release AAB using build_ver_aab.ps1
# and uploads/deploys it to the Google Play Store "internal" track.

$gplayDir = Join-Path (Get-Location) ".gplay"
$gplayPath = Join-Path $gplayDir "gplay.exe"
$gplayUrl = "https://github.com/tamtom/play-console-cli/releases/download/v0.5.3/gplay-windows-amd64.exe"

# 1. Ensure gplay.exe exists
if (-not (Test-Path $gplayDir)) {
    New-Item -ItemType Directory -Path $gplayDir -Force | Out-Null
}

if (-not (Test-Path $gplayPath)) {
    Write-Host "--------------------------------------------------"
    Write-Host "Downloading Google Play Console CLI (gplay)..." -ForegroundColor Cyan
    Write-Host "--------------------------------------------------"
    try {
        Invoke-WebRequest -Uri $gplayUrl -OutFile $gplayPath
        Write-Host "Download complete: $gplayPath" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download gplay.exe: $_"
        exit 1
    }
}

# 2. Resolve Service Account JSON key
$tempKeyFile = ""
$serviceAccountEnv = $env:GPLAY_SERVICE_ACCOUNT

if (-not $serviceAccountEnv) {
    # Check Doppler
    if (Get-Command doppler -ErrorAction SilentlyContinue) {
        Write-Host "Checking Doppler for GPLAY_SERVICE_ACCOUNT_KEY..." -ForegroundColor Green
        try {
            $secretJson = & doppler secrets download --project wreadom --config prd --format json --no-file --silent | ConvertFrom-Json
            if ($secretJson.GPLAY_SERVICE_ACCOUNT_KEY) {
                Write-Host "Found GPLAY_SERVICE_ACCOUNT_KEY in Doppler." -ForegroundColor Green
                $tempKeyFile = Join-Path $gplayDir "temp_service_account.json"
                $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllText($tempKeyFile, $secretJson.GPLAY_SERVICE_ACCOUNT_KEY, $Utf8NoBomEncoding)
                $env:GPLAY_SERVICE_ACCOUNT = $tempKeyFile
            }
        } catch {
            Write-Warning "Failed to read secrets from Doppler."
        }
    }
}

# Fallback to local file in project root if still not set
if (-not $env:GPLAY_SERVICE_ACCOUNT -and (Test-Path "play_store_key.json")) {
    $env:GPLAY_SERVICE_ACCOUNT = (Resolve-Path "play_store_key.json").Path
    Write-Host "Using credentials from local file: $env:GPLAY_SERVICE_ACCOUNT" -ForegroundColor Green
}

# Verify we have credentials
if (-not $env:GPLAY_SERVICE_ACCOUNT) {
    Write-Error @"
Authentication credentials not found.
To fix this, please do one of the following:
1. Save your service account JSON key to 'play_store_key.json' in the root directory.
2. Store your service account JSON key string in Doppler as 'GPLAY_SERVICE_ACCOUNT_KEY'.
3. Set the 'GPLAY_SERVICE_ACCOUNT' environment variable to the path of your JSON key file.
"@
    exit 1
}

# 3. Build the Release App Bundle
Write-Host "--------------------------------------------------"
Write-Host "Building Release App Bundle..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------"

& .\build_ver_aab.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed. Aborting Play Store upload."
    if ($tempKeyFile -and (Test-Path $tempKeyFile)) { Remove-Item $tempKeyFile -Force }
    exit 1
}

$aabPath = "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $aabPath)) {
    Write-Error "Could not find built app bundle at $aabPath"
    if ($tempKeyFile -and (Test-Path $tempKeyFile)) { Remove-Item $tempKeyFile -Force }
    exit 1
}

# 4. Upload/Release to Internal Track
Write-Host "--------------------------------------------------"
Write-Host "Releasing to Google Play Store (Internal track)..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------"

# Run the release command
& $gplayPath release --package in.wreadom.app --track internal --bundle $aabPath

$releaseExitCode = $LASTEXITCODE

# 5. Clean up temporary credentials if created from Doppler
if ($tempKeyFile -and (Test-Path $tempKeyFile)) {
    Write-Host "Cleaning up temporary credentials..." -ForegroundColor Green
    Remove-Item $tempKeyFile -Force
}

if ($releaseExitCode -eq 0) {
    Write-Host "--------------------------------------------------"
    Write-Host "Successfully published to Google Play Store (Internal)!" -ForegroundColor Green
    Write-Host "--------------------------------------------------"
} else {
    Write-Error "Play Store release failed with exit code $releaseExitCode"
    exit 1
}

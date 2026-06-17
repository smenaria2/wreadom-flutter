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
$serviceAccountKey = $env:GPLAY_SERVICE_ACCOUNT_JSON

if (-not $serviceAccountKey) {
    # Check Doppler
    if (Get-Command doppler -ErrorAction SilentlyContinue) {
        Write-Host "Checking Doppler for GPLAY_SERVICE_ACCOUNT_KEY..." -ForegroundColor Green
        try {
            $secretJson = & doppler secrets download --project wreadom --config prd --format json --no-file --silent | ConvertFrom-Json
            if ($secretJson.GPLAY_SERVICE_ACCOUNT_KEY) {
                Write-Host "Found GPLAY_SERVICE_ACCOUNT_KEY in Doppler." -ForegroundColor Green
                $serviceAccountKey = $secretJson.GPLAY_SERVICE_ACCOUNT_KEY
            }
        } catch {
            Write-Warning "Failed to read secrets from Doppler."
        }
    }
}

# Fallback to local file in project root if still not set
if (-not $serviceAccountKey -and (Test-Path "play_store_key.json")) {
    $serviceAccountKey = Get-Content -Raw "play_store_key.json"
    Write-Host "Using credentials from local file: play_store_key.json" -ForegroundColor Green
}

# Verify we have credentials
if (-not $serviceAccountKey) {
    Write-Error @"
Authentication credentials not found.
To fix this, please do one of the following:
1. Save your service account JSON key to 'play_store_key.json' in the root directory.
2. Store your service account JSON key string in Doppler as 'GPLAY_SERVICE_ACCOUNT_KEY'.
3. Set the 'GPLAY_SERVICE_ACCOUNT_JSON' environment variable to the path or content of your JSON key file.
"@
    exit 1
}

# Set environment variable for gplay CLI
$env:GPLAY_SERVICE_ACCOUNT_JSON = $serviceAccountKey


# 3. Build the Release App Bundle
Write-Host "--------------------------------------------------"
Write-Host "Building Release App Bundle..." -ForegroundColor Cyan
Write-Host "--------------------------------------------------"

& .\build_ver_aab.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed. Aborting Play Store upload."
    exit 1
}

$aabPath = "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $aabPath)) {
    Write-Error "Could not find built app bundle at $aabPath"
    exit 1
}

# 4. Extract Version and Build Number from pubspec.yaml
$versionString = ""
if (Test-Path "pubspec.yaml") {
    $content = Get-Content "pubspec.yaml"
    foreach ($line in $content) {
        if ($line -match '^version:\s*(.+)') {
            $versionString = $Matches[1].Trim()
            break
        }
    }
}

if (-not $versionString) {
    $versionString = "1.0.0" # Fallback default
}

# 5. Extract Git Commit Info for Release Notes
$commitInfo = "New release build."
if (Get-Command git -ErrorAction SilentlyContinue) {
    try {
        $commitInfo = & git log -n 5 --pretty=format:"- %s"
        if ($commitInfo -is [array]) {
            $commitInfo = $commitInfo -join "`n"
        }
        if ($commitInfo.Length -gt 450) {
            $commitInfo = $commitInfo.Substring(0, 450) + "..."
        }
    } catch {
        # Keep fallback
    }
}

# 6. Commit Version Bump and changes to Git first
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "--------------------------------------------------"
    Write-Host "Committing version bump to Git..." -ForegroundColor Cyan
    Write-Host "--------------------------------------------------"
    try {
        & git add -A
        $gitStatus = & git status --porcelain
        if ($gitStatus) {
            & git commit -m "release: version $versionString"
            Write-Host "Committed successfully to Git." -ForegroundColor Green
        } else {
            Write-Host "No changes to commit." -ForegroundColor Yellow
        }
    } catch {
        Write-Warning "Failed to commit to Git: $_"
    }
}

# 7. Upload/Release to Internal Track
Write-Host "--------------------------------------------------"
Write-Host "Releasing to Google Play Store (Internal track)..." -ForegroundColor Cyan
Write-Host "Version Name: $versionString"
Write-Host "Release Notes:`n$commitInfo"
Write-Host "--------------------------------------------------"

# Run the release command
& $gplayPath release --package in.wreadom.app --track internal --bundle $aabPath --version-name $versionString --release-notes $commitInfo

$releaseExitCode = $LASTEXITCODE


if ($releaseExitCode -eq 0) {
    Write-Host "--------------------------------------------------"
    Write-Host "Successfully published to Google Play Store (Internal)!" -ForegroundColor Green
    Write-Host "--------------------------------------------------"
} else {
    Write-Error "Play Store release failed with exit code $releaseExitCode"
    exit 1
}


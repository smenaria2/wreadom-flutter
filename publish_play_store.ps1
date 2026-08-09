# publish_play_store.ps1
# Builds, versions, commits, and publishes the app to Google Play internal,
# then deploys the matching web release through the existing root script.

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$gplayDir = Join-Path $projectRoot ".gplay"
$gplayPath = Join-Path $gplayDir "gplay.exe"
$gplayUrl = "https://github.com/tamtom/play-console-cli/releases/download/v0.5.3/gplay-windows-amd64.exe"
$aabPath = Join-Path $projectRoot "build\app\outputs\bundle\release\app-release.aab"
$pubspecPath = Join-Path $projectRoot "pubspec.yaml"

function Stop-Publish {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "Publish aborted: $Message" -ForegroundColor Red
    exit 1
}

try {
    Set-Location -LiteralPath $projectRoot

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Stop-Publish "Git is required for the release/version-control workflow."
    }
    $gitRoot = (& git rev-parse --show-toplevel 2>$null | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitRoot)) {
        Stop-Publish "The project root is not a Git repository."
    }
    if ((Resolve-Path -LiteralPath $gitRoot).Path -ne (Resolve-Path -LiteralPath $projectRoot).Path) {
        Stop-Publish "Run the repository's own root publish script; Git root mismatch detected."
    }

    $initialStatus = (& git status --porcelain --untracked-files=all | Out-String).Trim()
    if (-not [string]::IsNullOrWhiteSpace($initialStatus)) {
        Stop-Publish "The Git worktree must be clean before publishing. Commit or stash intended changes first; the script will commit only its generated pubspec version bump."
    }

    if (-not (Test-Path -LiteralPath $gplayDir)) {
        New-Item -ItemType Directory -Path $gplayDir -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $gplayPath -PathType Leaf)) {
        Write-Host "Downloading pinned Google Play Console CLI v0.5.3..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $gplayUrl -OutFile $gplayPath
    }

    $serviceAccountKey = $env:GPLAY_SERVICE_ACCOUNT_JSON
    if ([string]::IsNullOrWhiteSpace($serviceAccountKey) -and (Get-Command doppler -ErrorAction SilentlyContinue)) {
        Write-Host "Reading Google Play credentials from Doppler..." -ForegroundColor Cyan
        try {
            $secretJson = & doppler secrets download --project wreadom --config prd --format json --no-file --silent | ConvertFrom-Json
            if ($LASTEXITCODE -eq 0 -and $secretJson.GPLAY_SERVICE_ACCOUNT_KEY) {
                $serviceAccountKey = [string]$secretJson.GPLAY_SERVICE_ACCOUNT_KEY
            }
        } catch {
            Write-Warning "Doppler Google Play credentials were unavailable."
        }
    }
    $localKeyPath = Join-Path $projectRoot "play_store_key.json"
    if ([string]::IsNullOrWhiteSpace($serviceAccountKey) -and (Test-Path -LiteralPath $localKeyPath -PathType Leaf)) {
        $serviceAccountKey = $localKeyPath
        Write-Host "Using ignored play_store_key.json." -ForegroundColor Cyan
    }
    if ([string]::IsNullOrWhiteSpace($serviceAccountKey)) {
        Stop-Publish "Google Play credentials were not found in GPLAY_SERVICE_ACCOUNT_JSON, Doppler, or ignored play_store_key.json."
    }
    $env:GPLAY_SERVICE_ACCOUNT_JSON = $serviceAccountKey

    Write-Host "Building the production release App Bundle..." -ForegroundColor Cyan
    & (Join-Path $projectRoot "build_ver_aab.ps1")
    if ($LASTEXITCODE -ne 0) {
        Stop-Publish "The production App Bundle build failed."
    }
    if (-not (Test-Path -LiteralPath $aabPath -PathType Leaf)) {
        Stop-Publish "The expected App Bundle was not found at $aabPath"
    }

    $pubspec = Get-Content -Raw -LiteralPath $pubspecPath
    $versionMatch = [regex]::Match($pubspec, '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+\+[0-9]+)\s*$')
    if (-not $versionMatch.Success) {
        Stop-Publish "The built pubspec version could not be parsed."
    }
    $versionString = $versionMatch.Groups[1].Value

    $commitInfo = (& git log -n 5 --pretty=format:"- %s" | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($commitInfo)) {
        $commitInfo = "New release build."
    }
    if ($commitInfo.Length -gt 450) {
        $commitInfo = $commitInfo.Substring(0, 450) + "..."
    }

    & git add -- pubspec.yaml
    if ($LASTEXITCODE -ne 0) {
        Stop-Publish "Git could not stage the pubspec version bump."
    }
    $stagedFiles = @(& git diff --cached --name-only)
    if ($stagedFiles.Count -ne 1 -or $stagedFiles[0] -ne "pubspec.yaml") {
        Stop-Publish "Unexpected files are staged. Publishing will not continue."
    }
    & git commit -m "release: version $versionString"
    if ($LASTEXITCODE -ne 0) {
        Stop-Publish "Git could not commit the generated version bump."
    }

    Write-Host "Releasing $versionString to Google Play internal..." -ForegroundColor Cyan
    & $gplayPath release --package in.wreadom.app --track internal --bundle $aabPath --version-name $versionString --release-notes $commitInfo
    if ($LASTEXITCODE -ne 0) {
        Stop-Publish "Google Play release failed with exit code $LASTEXITCODE. The local version commit was retained for traceability."
    }

    Write-Host "Google Play release succeeded. Deploying the matching web app..." -ForegroundColor Green
    & (Join-Path $projectRoot "deploy_vercel.ps1") -Production
    if ($LASTEXITCODE -ne 0) {
        Stop-Publish "Google Play succeeded, but Vercel deployment failed."
    }

    Write-Host "Google Play internal and Vercel production releases succeeded." -ForegroundColor Green
    exit 0
} catch {
    Stop-Publish $_.Exception.Message
}

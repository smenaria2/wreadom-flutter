# build_ver_aab.ps1
# Updates only the build number and creates a production release App Bundle.

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$pubspecPath = Join-Path $projectRoot "pubspec.yaml"
$productionDefinesPath = Join-Path $projectRoot "dart_defines.production.json"
$temporaryDefinesPath = $null
$originalPubspec = $null
$pubspecChanged = $false

function Test-ProductionDefines {
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $defines = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    } catch {
        throw "Production Dart defines are not valid JSON: $Path"
    }

    $requiredKeys = @(
        "FIREBASE_ANDROID_API_KEY",
        "CLOUDINARY_CLOUD_NAME",
        "CLOUDINARY_UPLOAD_PRESET"
    )
    foreach ($key in $requiredKeys) {
        $property = $defines.PSObject.Properties[$key]
        $value = if ($null -eq $property) { "" } else { [string]$property.Value }
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw "Production Dart defines are missing required key: $key"
        }
        if ($value -match '(?i)(change[_-]?me|replace[_-]?me|your[_-]|example|placeholder)') {
            throw "Production Dart define $key still contains a placeholder value."
        }
    }

    $emulatorProperty = $defines.PSObject.Properties["USE_FIREBASE_EMULATORS"]
    if ($null -ne $emulatorProperty) {
        try {
            if ([System.Convert]::ToBoolean($emulatorProperty.Value)) {
                throw "Production builds cannot enable Firebase emulators."
            }
        } catch [System.FormatException] {
            throw "USE_FIREBASE_EMULATORS must be a JSON boolean or boolean string."
        }
    }
}

try {
    Set-Location -LiteralPath $projectRoot

    if (-not (Test-Path -LiteralPath $pubspecPath -PathType Leaf)) {
        throw "pubspec.yaml was not found in $projectRoot"
    }
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw "Flutter is not available on PATH."
    }

    $dartDefinesFile = $null
    if (Get-Command doppler -ErrorAction SilentlyContinue) {
        Write-Host "Fetching production Dart defines from Doppler..." -ForegroundColor Cyan
        try {
            $secretJson = (& doppler secrets download --project wreadom --config prd --format json --no-file --silent | Out-String).Trim()
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($secretJson)) {
                throw "Doppler returned no production configuration."
            }
            $temporaryDefinesPath = Join-Path ([System.IO.Path]::GetTempPath()) "wreadom_dart_defines_$PID.json"
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($temporaryDefinesPath, $secretJson, $utf8NoBom)
            $dartDefinesFile = $temporaryDefinesPath
        } catch {
            Write-Warning "Doppler production configuration was unavailable: $($_.Exception.Message)"
        }
    }

    if ($null -eq $dartDefinesFile) {
        if (-not (Test-Path -LiteralPath $productionDefinesPath -PathType Leaf)) {
            throw "Production Dart defines are required. Configure Doppler or create ignored dart_defines.production.json. Local/emulator defines are never used for release builds."
        }
        Write-Host "Using ignored dart_defines.production.json." -ForegroundColor Cyan
        $dartDefinesFile = $productionDefinesPath
    }
    Test-ProductionDefines -Path $dartDefinesFile

    $originalPubspec = [System.IO.File]::ReadAllText($pubspecPath)
    $versionPattern = '(?m)^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$'
    $versionMatch = [regex]::Match($originalPubspec, $versionPattern)
    if (-not $versionMatch.Success) {
        throw "Could not find a pubspec version in the form 1.2.3+45."
    }

    $versionName = $versionMatch.Groups[1].Value
    $previousBuildNumber = [int64]$versionMatch.Groups[2].Value
    $buildEpoch = [DateTimeOffset]::Parse('2024-01-01T00:00:00Z')
    $epochBuildNumber = [int64][Math]::Floor(([DateTimeOffset]::UtcNow - $buildEpoch).TotalSeconds)
    $buildNumber = [Math]::Max($epochBuildNumber, $previousBuildNumber + 1)
    $newVersion = "$versionName+$buildNumber"
    $updatedPubspec = [regex]::Replace($originalPubspec, $versionPattern, "version: $newVersion", 1)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($pubspecPath, $updatedPubspec, $utf8NoBom)
    $pubspecChanged = $true

    Write-Host "--------------------------------------------------"
    Write-Host "Building production App Bundle $newVersion..." -ForegroundColor Cyan
    Write-Host "--------------------------------------------------"
    & flutter build appbundle --release "--dart-define-from-file=$dartDefinesFile"
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter App Bundle build failed with exit code $LASTEXITCODE."
    }

    $aabPath = Join-Path $projectRoot "build\app\outputs\bundle\release\app-release.aab"
    if (-not (Test-Path -LiteralPath $aabPath -PathType Leaf)) {
        throw "Flutter reported success but the App Bundle was not created at $aabPath"
    }

    Write-Host "Success! App Bundle is ready at: $aabPath" -ForegroundColor Green
    exit 0
} catch {
    if ($pubspecChanged -and $null -ne $originalPubspec) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($pubspecPath, $originalPubspec, $utf8NoBom)
        Write-Warning "The failed build's pubspec version change was rolled back."
    }
    Write-Host "Build aborted: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if ($null -ne $temporaryDefinesPath -and (Test-Path -LiteralPath $temporaryDefinesPath)) {
        Remove-Item -LiteralPath $temporaryDefinesPath -Force
    }
}

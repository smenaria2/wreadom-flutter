# build_ver_apk.ps1
# This script keeps the app version name the same, updates the build number
# to seconds since the app build epoch, and builds the release APK.

$pubspecPath = "pubspec.yaml"

if (-not (Test-Path $pubspecPath)) {
    Write-Error "pubspec.yaml not found in the current directory."
    exit 1
}

$content = Get-Content $pubspecPath
$newContent = @()
$foundVersion = $false
$version = ""
$buildNumber = 0
$buildEpoch = [DateTimeOffset]::Parse('2024-01-01T00:00:00Z')
$now = [DateTimeOffset]::UtcNow
$epochBuildNumber = [int64][Math]::Floor(($now - $buildEpoch).TotalSeconds)

foreach ($line in $content) {
    if ($line -match '^version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)') {
        $version = $Matches[1]
        $buildNumber = $epochBuildNumber
        $newVersionLine = "version: $version+$buildNumber"
        $newContent += $newVersionLine
        $foundVersion = $true
    } else {
        $newContent += $line
    }
}

if ($foundVersion) {
    # Write with UTF8 without BOM to keep it clean for Flutter
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllLines((Resolve-Path $pubspecPath), $newContent, $Utf8NoBomEncoding)
    
    Write-Host "--------------------------------------------------"
    Write-Host "Updated pubspec.yaml to version: $version+$buildNumber"
    Write-Host "Starting Flutter Build (APK Release)..."
    Write-Host "--------------------------------------------------"
    
    flutter build apk --release
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nSuccess! APK is ready at: build\app\outputs\flutter-apk\app-release.apk"
    } else {
        Write-Error "`nBuild failed with exit code $LASTEXITCODE"
    }
} else {
    Write-Error "Could not find version line (e.g., 'version: 1.0.0+1') in pubspec.yaml"
}

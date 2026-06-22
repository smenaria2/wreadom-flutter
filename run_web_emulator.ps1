# run_web_emulator.ps1
# Script to run Flutter Web Preview with Emulator settings at http://localhost:3000/
# It will first check for any running process on port 3000 and kill it.

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Starting Flutter Web Emulator (Port 3000)   " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Step 1: Find and kill any process occupying port 3000
Write-Host "[Step 1/2] Checking port 3000..." -ForegroundColor Yellow
$connection = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue

if ($connection) {
    $pids = $connection.OwningProcess | Select-Object -Unique
    foreach ($targetPid in $pids) {
        $proc = Get-Process -Id $targetPid -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "Found process '$($proc.Name)' (PID $targetPid) listening on port 3000." -ForegroundColor Yellow
            Write-Host "Terminating process..." -ForegroundColor Red
            Stop-Process -Id $targetPid -Force -ErrorAction SilentlyContinue
        }
    }
    # Small pause to allow the port to release
    Start-Sleep -Seconds 2
} else {
    Write-Host "Port 3000 is free." -ForegroundColor Green
}

# Step 2: Run Flutter Web with Emulator Settings
Write-Host "`n[Step 2/2] Launching Flutter Web Emulator..." -ForegroundColor Cyan
Write-Host "[Info] Open http://localhost:3000/ (Firebase Auth requires localhost authorized domain)." -ForegroundColor Green

$dartDefinesFile = "dart_defines.emulator.json"

if (Get-Command doppler -ErrorAction SilentlyContinue) {
    Write-Host "[Info] Fetching latest secrets from Doppler..." -ForegroundColor Green
    try {
        $secretJson = & doppler secrets download --project wreadom --config prd --format json --no-file --silent
        if ($LASTEXITCODE -ne 0 -or -not $secretJson) {
            throw "Doppler secrets download failed."
        }
        
        # Parse Doppler JSON and inject emulator overrides
        $secrets = $secretJson | ConvertFrom-Json
        $secrets | Add-Member -NotePropertyName "USE_FIREBASE_EMULATORS" -NotePropertyValue "true" -Force
        $secrets | Add-Member -NotePropertyName "FIREBASE_EMULATOR_HOST" -NotePropertyValue "127.0.0.1" -Force
        $secrets | Add-Member -NotePropertyName "FIREBASE_FIRESTORE_EMULATOR_PORT" -NotePropertyValue 8180 -Force
        
        # Convert back to JSON string
        $updatedJson = $secrets | ConvertTo-Json -Compress

        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText((Join-Path (Get-Location) $dartDefinesFile), $updatedJson, $Utf8NoBomEncoding)
        Write-Host "[Info] Successfully generated $dartDefinesFile with emulator overrides." -ForegroundColor Green
    } catch {
        Write-Warning "Failed to download secrets from Doppler. Falling back to existing emulator file if available: $_"
    }
}

$runCmd = "flutter run -d web-server --web-hostname=0.0.0.0 --web-port=3000"

if (Test-Path $dartDefinesFile) {
    Write-Host "[Info] Found $dartDefinesFile. Injecting Dart defines." -ForegroundColor Green
    $runCmd += " --dart-define-from-file=$dartDefinesFile"
} else {
    Write-Host "[Warning] $dartDefinesFile not found. Running without custom Dart defines." -ForegroundColor Yellow
}

Write-Host "Running: $runCmd" -ForegroundColor DarkGray
Invoke-Expression $runCmd

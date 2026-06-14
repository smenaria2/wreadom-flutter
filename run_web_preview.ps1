# run_web_preview.ps1
# Script to run Flutter Web Preview at http://localhost:3000/
# It will first check for any running process on port 3000 and kill it.

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Starting Flutter Web Preview (Port 3000)   " -ForegroundColor Cyan
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

# Step 2: Run Flutter Web Preview
Write-Host "`n[Step 2/2] Launching Flutter Web Preview..." -ForegroundColor Cyan
Write-Host "[Info] Open http://localhost:3000/ (Firebase Auth requires localhost authorized domain)." -ForegroundColor Green

$dartDefinesFile = "dart_defines.local.json"

if (Get-Command doppler -ErrorAction SilentlyContinue) {
    Write-Host "[Info] Fetching latest secrets from Doppler..." -ForegroundColor Green
    try {
        $secretJson = & doppler secrets download --project wreadom --config prd --format json --no-file --silent
        if ($LASTEXITCODE -ne 0 -or -not $secretJson) {
            throw "Doppler secrets download failed."
        }
        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText((Join-Path (Get-Location) $dartDefinesFile), ($secretJson -join [Environment]::NewLine), $Utf8NoBomEncoding)
    } catch {
        Write-Warning "Failed to download secrets from Doppler. Falling back to existing local file if available."
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

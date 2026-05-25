# deploy_vercel.ps1
# Script to build Flutter Web and deploy to Vercel with correct environment variables / dart defines.
# Usage:
#   .\deploy_vercel.ps1             - Deploys a Preview version
#   .\deploy_vercel.ps1 -Production - Deploys a Production version

param (
    [switch]$Production
)

$ErrorActionPreference = "Stop"

# Determine target environments
$targetEnv = "preview"
$prodFlag = ""
if ($Production) {
    $targetEnv = "production"
    $prodFlag = "--prod"
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " Starting Vercel Deployment ($targetEnv) " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Step 1: Resolve Dart defines (Env vars)
$dartDefinesFile = ""
$isTempDefines = $false

if (Test-Path "dart_defines.local.json") {
    Write-Host "[Info] Found dart_defines.local.json. Using it for build." -ForegroundColor Green
    $dartDefinesFile = "dart_defines.local.json"
} else {
    Write-Host "[Info] dart_defines.local.json not found. Checking environment variables..." -ForegroundColor Yellow
    
    $defines = @{}
    $envKeys = @(
        "FIREBASE_WEB_API_KEY",
        "FIREBASE_ANDROID_API_KEY",
        "FIREBASE_IOS_API_KEY",
        "FIREBASE_WINDOWS_API_KEY",
        "CLOUDINARY_CLOUD_NAME",
        "CLOUDINARY_UPLOAD_PRESET",
        "USE_FIREBASE_EMULATORS",
        "FIREBASE_EMULATOR_HOST"
    )

    foreach ($key in $envKeys) {
        $val = [System.Environment]::GetEnvironmentVariable($key)
        if ($val) {
            if ($key -eq "USE_FIREBASE_EMULATORS") {
                $defines[$key] = [System.Convert]::ToBoolean($val)
            } else {
                $defines[$key] = $val
            }
        }
    }

    if ($defines.Count -gt 0) {
        Write-Host "[Info] Found environment variables. Creating temporary dart_defines.temp.json..." -ForegroundColor Green
        $defines | ConvertTo-Json | Out-File -FilePath "dart_defines.temp.json" -Encoding utf8
        $dartDefinesFile = "dart_defines.temp.json"
        $isTempDefines = $true
    } else {
        Write-Host "[Warning] No dart_defines.local.json found and no environment variables set." -ForegroundColor Red
        Write-Host "Building without custom Dart defines." -ForegroundColor Red
    }
}

# Step 2: Build Flutter Web
Write-Host "`n[Step 1/3] Building Flutter Web..." -ForegroundColor Cyan
$buildCmd = "flutter build web --release"
if ($dartDefinesFile) {
    $buildCmd += " --dart-define-from-file=$dartDefinesFile"
}

Write-Host "Running: $buildCmd" -ForegroundColor DarkGray
Invoke-Expression $buildCmd

# Step 3: Run Vercel Local Build (overriding buildCommand to null)
Write-Host "`n[Step 2/3] Building Vercel Package..." -ForegroundColor Cyan
$vercelBuildCmd = "vercel build --local-config vercel.local.json"
if ($Production) {
    $vercelBuildCmd += " --prod"
}

Write-Host "Running: $vercelBuildCmd" -ForegroundColor DarkGray
Invoke-Expression $vercelBuildCmd

# Step 4: Deploy prebuilt application to Vercel
Write-Host "`n[Step 3/3] Deploying to Vercel..." -ForegroundColor Cyan
$vercelDeployCmd = "vercel --prebuilt"
if ($Production) {
    $vercelDeployCmd += " --prod"
}

Write-Host "Running: $vercelDeployCmd" -ForegroundColor DarkGray
Invoke-Expression $vercelDeployCmd

# Cleanup
if ($isTempDefines -and (Test-Path "dart_defines.temp.json")) {
    Remove-Item "dart_defines.temp.json" -Force
}

Write-Host "`n=============================================" -ForegroundColor Green
Write-Host " Deployment completed successfully! " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

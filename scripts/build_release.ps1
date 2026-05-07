param(
  [ValidateSet('apk', 'appbundle', 'ipa')]
  [string] $Target = 'appbundle',

  [switch] $Release,

  [string] $BuildName,

  [string] $BuildNumber,

  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $FlutterArgs
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$pubspecPath = Join-Path $repoRoot 'pubspec.yaml'
$defaultDartDefinesPath = Join-Path $repoRoot 'dart_defines.local.json'
$pubspecVersionLine = Get-Content -Path $pubspecPath |
  Where-Object { $_ -match '^\s*version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?\s*$' } |
  Select-Object -First 1

if (-not $pubspecVersionLine) {
  throw "Could not find a Flutter version line like 'version: 1.0.0+1' in pubspec.yaml."
}

$pubspecVersionLine -match '^\s*version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+([0-9]+))?\s*$' | Out-Null

if (-not $BuildName) {
  $BuildName = $Matches[1]
}

if (-not $BuildNumber) {
  $buildEpoch = [DateTimeOffset]::Parse('2024-01-01T00:00:00Z')
  $now = [DateTimeOffset]::UtcNow
  $BuildNumber = [int64][Math]::Floor(($now - $buildEpoch).TotalSeconds)
}

$parsedBuildNumber = 0L
if (-not [int64]::TryParse($BuildNumber, [ref] $parsedBuildNumber) -or $parsedBuildNumber -lt 1) {
  throw 'Build number must be a positive integer.'
}

if (($Target -eq 'apk' -or $Target -eq 'appbundle') -and $parsedBuildNumber -gt 2100000000) {
  throw 'Android build numbers must be 2,100,000,000 or lower.'
}

Write-Host "Building $Target with version $BuildName ($BuildNumber)"
Push-Location $repoRoot
try {
  $buildArgs = @($Target, "--build-name=$BuildName", "--build-number=$BuildNumber")
  if ($Release) {
    $buildArgs += '--release'
  }

  $hasDartDefinesFromFile = $FlutterArgs |
    Where-Object { $_ -like '--dart-define-from-file*' } |
    Select-Object -First 1
  if (-not $hasDartDefinesFromFile -and (Test-Path -LiteralPath $defaultDartDefinesPath)) {
    Write-Host "Using Dart defines from $defaultDartDefinesPath"
    $buildArgs += "--dart-define-from-file=$defaultDartDefinesPath"
  }

  $buildArgs += $FlutterArgs

  & flutter build @buildArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}

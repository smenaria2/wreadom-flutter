param (
    [string]$Port = ""
)

$IP = "172.47.48.164"

if ($Port -eq "") {
    $Port = Read-Host "Enter the Port shown on your phone's Wireless Debugging screen"
}

if ($Port -ne "") {
    Write-Host "Connecting to $IP:$Port..." -ForegroundColor Cyan
    adb connect "$IP:$Port"
    Start-Sleep -Seconds 2
    adb devices
} else {
    Write-Host "No port provided. Connection cancelled." -ForegroundColor Red
}

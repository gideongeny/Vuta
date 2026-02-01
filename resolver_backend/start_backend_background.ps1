# VUTA Resolver Backend - Start in Background (Windows)
# This script starts the backend as a background process

Write-Host "Starting VUTA Resolver Backend in background..." -ForegroundColor Green

# Change to script directory
Set-Location $PSScriptRoot

# Check if already running
$existing = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*server.py*"
}

if ($existing) {
    Write-Host "Backend is already running!" -ForegroundColor Yellow
    Write-Host "PID: $($existing.Id)" -ForegroundColor Cyan
    exit 0
}

# Start Python process in background
$job = Start-Process python -ArgumentList "server.py" -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru

if ($job) {
    Write-Host "Backend started successfully!" -ForegroundColor Green
    Write-Host "PID: $($job.Id)" -ForegroundColor Cyan
    Write-Host "Server running on http://localhost:8080" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To stop the backend, run: stop_backend.ps1" -ForegroundColor Yellow
    Write-Host "Or kill the process: Stop-Process -Id $($job.Id)" -ForegroundColor Yellow
} else {
    Write-Host "Failed to start backend!" -ForegroundColor Red
    exit 1
}

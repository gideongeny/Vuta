# VUTA Resolver Backend - Stop Script
Write-Host "Stopping VUTA Resolver Backend..." -ForegroundColor Yellow

# Find Python processes running server.py
$processes = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
    try {
        $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine
        $cmdLine -like "*server.py*"
    } catch {
        $false
    }
}

if ($processes) {
    foreach ($proc in $processes) {
        Write-Host "Stopping process PID: $($proc.Id)" -ForegroundColor Cyan
        Stop-Process -Id $proc.Id -Force
    }
    Write-Host "Backend stopped successfully!" -ForegroundColor Green
} else {
    Write-Host "No backend process found running." -ForegroundColor Yellow
}

# Test VUTA Backend
Write-Host "Testing VUTA Resolver Backend..." -ForegroundColor Cyan
Write-Host ""

# Test health endpoint
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -Method GET -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✓ Backend is running!" -ForegroundColor Green
        Write-Host "Response: $($response.Content)" -ForegroundColor Cyan
    } else {
        Write-Host "✗ Backend returned status: $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Backend is not running or not accessible!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Start the backend with: .\start_backend.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Backend is ready to use!" -ForegroundColor Green

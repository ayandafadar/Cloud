<#
.SYNOPSIS
    Starts the full Blue-Green demonstration environment on http://localhost:8080.

.DESCRIPTION
    1. Ensures Kubernetes production service selector is set to Blue (v1.0.0).
    2. Opens port forwards for Blue (8081) and Green (8082).
    3. Starts the DeployShift dynamic gateway on port 8080.
    4. Automatically launches the interactive browser dashboard at http://localhost:8080/console.
#>

$ErrorActionPreference = "Continue"

Write-Host "`n========================================================" -ForegroundColor Cyan
Write-Host "   DeployShift: Starting Blue-Green Live Environment    " -ForegroundColor Cyan
Write-Host "========================================================`n" -ForegroundColor Cyan

# 1. Clean up existing port forward or gateway processes
Write-Host "Cleaning up previous background proxies..." -ForegroundColor Yellow
Stop-Process -Name kubectl -Force -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name = 'node.exe'" | Where-Object { $_.CommandLine -like "*gateway.js*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

# 2. Reset production Kubernetes service to Blue
Write-Host "Resetting Kubernetes production selector to Blue..." -ForegroundColor Yellow
kubectl set selector service blue-green-api-production -n blue-green "app=blue-green-api,version=blue"

# 3. Start preview port-forwards
Write-Host "Establishing Kubernetes pod streams (Blue: 8081, Green: 8082)..." -ForegroundColor Yellow
Start-Process -FilePath "kubectl" -ArgumentList "port-forward svc/blue-green-api-blue-preview -n blue-green 8081:80" -WindowStyle Hidden
Start-Process -FilePath "kubectl" -ArgumentList "port-forward svc/blue-green-api-green-preview -n blue-green 8082:80" -WindowStyle Hidden

Start-Sleep -Seconds 2

# 4. Start gateway
Write-Host "Starting dynamic gateway router on port 8080..." -ForegroundColor Yellow
Start-Process -FilePath "node" -ArgumentList "gateway.js" -WindowStyle Hidden

Start-Sleep -Seconds 2

Write-Host "`n[READY] Project is running live!" -ForegroundColor Green
Write-Host "  -> Web Console: http://localhost:8080/console" -ForegroundColor Cyan
Write-Host "  -> API Target:  http://localhost:8080/api/version (Initial: Blue)" -ForegroundColor Cyan
Write-Host "`nRun 'npm test' in any terminal to trigger release failure & auto-switch to Green!`n" -ForegroundColor Magenta

# Launch default browser
Start-Process "http://localhost:8080/console"

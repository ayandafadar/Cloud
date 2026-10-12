<#
.SYNOPSIS
    Switches production traffic back to Blue (v1.0.0).

.DESCRIPTION
    Patches the production Service selector to route traffic to Blue pods.
    This is functionally identical to a rollback — Blue has been running
    continuously alongside Green.
#>

$ErrorActionPreference = "Stop"
$Namespace = "blue-green"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Switching Traffic -> Blue (v1.0.0)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verify Blue pods are ready
Write-Host "Checking Blue pod readiness..." -ForegroundColor Yellow
$bluePods = kubectl get pods -n $Namespace -l "app=blue-green-api,version=blue" -o jsonpath="{.items[*].status.containerStatuses[*].ready}" 2>&1
if (-not $bluePods -or $bluePods -match "false" -or -not ($bluePods -match "true")) {
    Write-Host "[FAIL] Not all Blue pods are ready. Cannot switch traffic." -ForegroundColor Red
    kubectl get pods -n $Namespace -l "app=blue-green-api,version=blue"
    exit 1
}
Write-Host "[PASS] All Blue pods are ready" -ForegroundColor Green

# Update the service selector to Blue
Write-Host "`nUpdating production Service selector to 'blue'..." -ForegroundColor Yellow
kubectl set selector service blue-green-api-production -n $Namespace "app=blue-green-api,version=blue"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Failed to update production Service selector" -ForegroundColor Red
    exit 1
}

# Verify
Start-Sleep -Seconds 2
$newVersion = kubectl get svc blue-green-api-production -n $Namespace -o jsonpath='{.spec.selector.version}' 2>&1
Write-Host "Production Service selector: version=$newVersion" -ForegroundColor Cyan

if ($newVersion -ne "blue") {
    Write-Host "[FAIL] Service selector did not update correctly" -ForegroundColor Red
    exit 1
}

Write-Host "`nProduction endpoints:" -ForegroundColor Cyan
kubectl get endpoints blue-green-api-production -n $Namespace

Write-Host "`n[DONE] Production traffic is now routed to Blue (v1.0.0).`n" -ForegroundColor Green

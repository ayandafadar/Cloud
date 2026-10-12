<#
.SYNOPSIS
    Switches production traffic from Blue to Green.

.DESCRIPTION
    Patches the production Service selector to route traffic to Green pods.
    Verifies that Green is ready before switching, and validates the switch
    by checking the active version after patching.
#>

$ErrorActionPreference = "Stop"
$Namespace = "blue-green"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Switching Traffic -> Green (v2.0.0)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verify Green pods are ready
Write-Host "Checking Green pod readiness..." -ForegroundColor Yellow
$greenPods = kubectl get pods -n $Namespace -l "app=blue-green-api,version=green" -o jsonpath="{.items[*].status.containerStatuses[*].ready}" 2>&1
if (-not $greenPods -or $greenPods -match "false" -or -not ($greenPods -match "true")) {
    Write-Host "[FAIL] Not all Green pods are ready. Cannot switch traffic." -ForegroundColor Red
    Write-Host "Green pod status:" -ForegroundColor Yellow
    kubectl get pods -n $Namespace -l "app=blue-green-api,version=green"
    exit 1
}
Write-Host "[PASS] All Green pods are ready" -ForegroundColor Green

# Current selector
Write-Host "`nCurrent production Service selector:" -ForegroundColor Yellow
kubectl get svc blue-green-api-production -n $Namespace -o jsonpath='{.spec.selector.version}'

# Update the service selector to Green
Write-Host "`n`nUpdating production Service selector to 'green'..." -ForegroundColor Yellow
kubectl set selector service blue-green-api-production -n $Namespace "app=blue-green-api,version=green"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Failed to update production Service selector" -ForegroundColor Red
    exit 1
}

# Verify new selector
Start-Sleep -Seconds 2
$newVersion = kubectl get svc blue-green-api-production -n $Namespace -o jsonpath='{.spec.selector.version}' 2>&1
Write-Host "New production Service selector: version=$newVersion" -ForegroundColor Cyan

if ($newVersion -ne "green") {
    Write-Host "[FAIL] Service selector did not update correctly" -ForegroundColor Red
    exit 1
}

# Show endpoints
Write-Host "`nProduction endpoints:" -ForegroundColor Cyan
kubectl get endpoints blue-green-api-production -n $Namespace

Write-Host "`n[DONE] Production traffic is now routed to Green (v2.0.0).`n" -ForegroundColor Green
Write-Host "Verify with:  kubectl port-forward svc/blue-green-api-production -n $Namespace 8080:80" -ForegroundColor Yellow
Write-Host "Then:         curl http://localhost:8080/api/version`n" -ForegroundColor Yellow

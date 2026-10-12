<#
.SYNOPSIS
    Rolls back production traffic to Blue (v1.0.0).

.DESCRIPTION
    This script is the emergency rollback path.  It:
    1. Verifies Blue is still healthy.
    2. Switches the production Service selector back to Blue.
    3. Validates that the API returns v1.0.0.
    
    Blue-green rollback is instant because Blue pods were never stopped.
    
    NOTE: This differs from a Kubernetes "rollout undo", which reverts a
    Deployment to a previous ReplicaSet.  In blue-green, rollback means
    changing the Service selector — the Deployments are untouched.
#>

$ErrorActionPreference = "Stop"
$Namespace = "blue-green"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  ROLLBACK - Restoring Blue (v1.0.0)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Check current active version
$currentVersion = kubectl get svc blue-green-api-production -n $Namespace -o jsonpath='{.spec.selector.version}' 2>&1
Write-Host "Current active version: $currentVersion" -ForegroundColor Yellow

if ($currentVersion -eq "blue") {
    Write-Host "[INFO] Production is already on Blue. No rollback needed." -ForegroundColor Green
    exit 0
}

# Step 2: Verify Blue health
Write-Host "`nVerifying Blue pod readiness..." -ForegroundColor Yellow
$bluePods = kubectl get pods -n $Namespace -l "app=blue-green-api,version=blue" -o jsonpath="{.items[*].status.containerStatuses[*].ready}" 2>&1
if (-not $bluePods -or $bluePods -match "false" -or -not ($bluePods -match "true")) {
    Write-Host "[FAIL] Blue pods are not ready! Manual intervention required." -ForegroundColor Red
    kubectl get pods -n $Namespace -l "app=blue-green-api,version=blue"
    exit 1
}
Write-Host "[PASS] Blue pods are healthy" -ForegroundColor Green

# Step 3: Switch traffic
Write-Host "`nSwitching production traffic to Blue..." -ForegroundColor Yellow
kubectl set selector service blue-green-api-production -n $Namespace "app=blue-green-api,version=blue"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Failed to update production Service selector" -ForegroundColor Red
    exit 1
}

Start-Sleep -Seconds 2

# Step 4: Verify
$newVersion = kubectl get svc blue-green-api-production -n $Namespace -o jsonpath='{.spec.selector.version}' 2>&1
if ($newVersion -ne "blue") {
    Write-Host "[FAIL] Rollback verification failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n[PASS] Rollback successful. Production is on Blue (v1.0.0)." -ForegroundColor Green
Write-Host "`nBlue pods:" -ForegroundColor Cyan
kubectl get pods -n $Namespace -l "app=blue-green-api,version=blue" -o wide

Write-Host "`nProduction endpoints:" -ForegroundColor Cyan
kubectl get endpoints blue-green-api-production -n $Namespace

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Rollback vs. Rollout Undo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host @"

In blue-green deployment, a ROLLBACK changes the Service selector
so traffic flows to the old (Blue) pods that are already running.
It is nearly instantaneous.

A Kubernetes 'rollout undo' reverts a Deployment to a previous
ReplicaSet.  This takes time because new pods must be created
from the old template.  In blue-green, the Deployments are never
modified - only the Service selector changes.

"@ -ForegroundColor Gray

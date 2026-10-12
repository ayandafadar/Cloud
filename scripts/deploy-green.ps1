<#
.SYNOPSIS
    Deploys the Green (v2.0.0) release to Kubernetes alongside Blue.

.DESCRIPTION
    Deploys Green without affecting production traffic (which remains
    on Blue).  Waits for the rollout and verifies readiness before
    allowing a traffic switch.
#>

$ErrorActionPreference = "Stop"
$Namespace = "blue-green"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Deploying Green (v2.0.0)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verify cluster connectivity
kubectl cluster-info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Cannot reach Kubernetes cluster." -ForegroundColor Red
    exit 1
}

# Verify namespace exists
$ns = kubectl get namespace $Namespace --ignore-not-found -o name 2>&1
if (-not $ns) {
    Write-Host "[FAIL] Namespace '$Namespace' does not exist. Deploy Blue first." -ForegroundColor Red
    exit 1
}

# Deploy Green
Write-Host "Deploying Green Deployment..." -ForegroundColor Yellow
kubectl apply -f k8s/green-deployment.yaml

# Wait for rollout
Write-Host "`nWaiting for Green rollout to complete (timeout: 120s)..." -ForegroundColor Yellow
kubectl rollout status deployment/blue-green-api-green -n $Namespace --timeout=120s
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Green rollout did not complete in time" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Green rollout complete" -ForegroundColor Green

# Verify pods
Write-Host "`nGreen pods:" -ForegroundColor Cyan
kubectl get pods -n $Namespace -l "app=blue-green-api,version=green" -o wide

# Smoke test via preview service
Write-Host "`nProduction traffic is still on Blue." -ForegroundColor Yellow
Write-Host "Test Green independently:" -ForegroundColor Yellow
Write-Host "  kubectl port-forward svc/blue-green-api-green-preview -n $Namespace 8081:80" -ForegroundColor Yellow
Write-Host "  curl http://localhost:8081/api/version`n" -ForegroundColor Yellow

Write-Host "[DONE] Green (v2.0.0) deployed and ready. Run switch-to-green.ps1 to switch traffic.`n" -ForegroundColor Green

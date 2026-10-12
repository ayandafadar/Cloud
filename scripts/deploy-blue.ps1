<#
.SYNOPSIS
    Deploys the Blue (v1.0.0) release to Kubernetes.

.DESCRIPTION
    Creates the namespace, ConfigMap, Blue Deployment, production Service
    (pointing to Blue), and preview services.  Waits for the rollout to
    complete and verifies pod readiness.
#>

$ErrorActionPreference = "Stop"
$Namespace = "blue-green"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Deploying Blue (v1.0.0)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Verify cluster connectivity
Write-Host "Verifying Kubernetes cluster..." -ForegroundColor Yellow
kubectl cluster-info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Cannot reach Kubernetes cluster. Run check-prerequisites.ps1 first." -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Cluster is reachable" -ForegroundColor Green

# Apply namespace and config
Write-Host "`nCreating namespace and ConfigMap..." -ForegroundColor Yellow
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml

# Deploy Blue
Write-Host "`nDeploying Blue Deployment..." -ForegroundColor Yellow
kubectl apply -f k8s/blue-deployment.yaml

# Apply production service pointing to Blue
Write-Host "`nApplying production Service (→ Blue)..." -ForegroundColor Yellow
kubectl apply -f k8s/production-service.yaml

# Apply preview services
Write-Host "`nApplying preview Services..." -ForegroundColor Yellow
kubectl apply -f k8s/preview-services.yaml

# Wait for rollout
Write-Host "`nWaiting for Blue rollout to complete (timeout: 120s)..." -ForegroundColor Yellow
kubectl rollout status deployment/blue-green-api-blue -n $Namespace --timeout=120s
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Blue rollout did not complete in time" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Blue rollout complete" -ForegroundColor Green

# Verify pods
Write-Host "`nBlue pods:" -ForegroundColor Cyan
kubectl get pods -n $Namespace -l "app=blue-green-api,version=blue" -o wide

# Verify service selector
Write-Host "`nProduction Service selector:" -ForegroundColor Cyan
kubectl get svc blue-green-api-production -n $Namespace -o jsonpath='{.spec.selector}' | ConvertFrom-Json | Format-List

Write-Host "`n[DONE] Blue (v1.0.0) is live and serving production traffic.`n" -ForegroundColor Green
Write-Host "Test with:  kubectl port-forward svc/blue-green-api-production -n $Namespace 8080:80" -ForegroundColor Yellow
Write-Host "Then:       curl http://localhost:8080/api/version`n" -ForegroundColor Yellow

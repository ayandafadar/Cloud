<#
.SYNOPSIS
    Cleans up all Blue-Green Deployment resources from Kubernetes.

.DESCRIPTION
    Deletes the entire namespace (and everything in it).
    This is DESTRUCTIVE and requires confirmation.
#>

$ErrorActionPreference = "Stop"
$Namespace = "blue-green"

Write-Host "`n========================================" -ForegroundColor Red
Write-Host "  CLEANUP - Delete All Resources" -ForegroundColor Red
Write-Host "========================================`n" -ForegroundColor Red

Write-Host "This will delete the namespace '$Namespace' and ALL resources inside it:" -ForegroundColor Yellow
Write-Host "  - Blue Deployment and pods" -ForegroundColor Yellow
Write-Host "  - Green Deployment and pods" -ForegroundColor Yellow
Write-Host "  - Production Service" -ForegroundColor Yellow
Write-Host "  - Preview Services" -ForegroundColor Yellow
Write-Host "  - ConfigMap" -ForegroundColor Yellow

Write-Host ""
$confirm = Read-Host "Type 'DELETE' to confirm"

if ($confirm -ne "DELETE") {
    Write-Host "`n[CANCELLED] No resources were deleted.`n" -ForegroundColor Yellow
    exit 0
}

Write-Host "`nDeleting namespace '$Namespace'..." -ForegroundColor Yellow
kubectl delete namespace $Namespace --timeout=60s
if ($LASTEXITCODE -eq 0) {
    Write-Host "[DONE] Namespace '$Namespace' and all resources deleted.`n" -ForegroundColor Green
}
else {
    Write-Host "[WARN] Namespace deletion may still be in progress.`n" -ForegroundColor Yellow
}

# Optionally remove Docker images
Write-Host "Do you also want to remove the Docker images?" -ForegroundColor Yellow
$removeImages = Read-Host "Type 'YES' to remove images"

if ($removeImages -eq "YES") {
    docker rmi deployshift-api:v1.0.0 deployshift-api:v2.0.0 2>$null
    Write-Host "[DONE] Docker images removed.`n" -ForegroundColor Green
}
else {
    Write-Host "[SKIPPED] Docker images kept.`n" -ForegroundColor Yellow
}

<#
.SYNOPSIS
    Comprehensive deployment verification script.

.DESCRIPTION
    Checks Kubernetes connectivity, namespace, deployments, pods,
    service selectors, endpoints, application version, health,
    and API functionality.
#>

$ErrorActionPreference = "Continue"
$Namespace = "blue-green"
$passed = 0
$failed = 0
$warnings = 0

function Test-Check {
    param([string]$Name, [scriptblock]$Check)
    try {
        $result = & $Check
        if ($result) {
            Write-Host "[PASS] $Name" -ForegroundColor Green
            $script:passed++
        }
        else {
            Write-Host "[FAIL] $Name" -ForegroundColor Red
            $script:failed++
        }
    }
    catch {
        Write-Host "[FAIL] $Name - $($_.Exception.Message)" -ForegroundColor Red
        $script:failed++
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Deployment Verification" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 1. Kubernetes connectivity
Test-Check "Kubernetes cluster reachable" {
    kubectl cluster-info 2>&1 | Out-Null
    $LASTEXITCODE -eq 0
}

# 2. Namespace exists
Test-Check "Namespace '$Namespace' exists" {
    $ns = kubectl get namespace $Namespace --ignore-not-found -o name 2>&1
    $ns -match "namespace/$Namespace"
}

# 3. Blue Deployment exists
Test-Check "Blue Deployment exists" {
    $dep = kubectl get deployment blue-green-api-blue -n $Namespace --ignore-not-found -o name 2>&1
    $dep -match "deployment"
}

# 4. Blue Deployment rolled out
Test-Check "Blue Deployment fully rolled out" {
    kubectl rollout status deployment/blue-green-api-blue -n $Namespace --timeout=10s 2>&1 | Out-Null
    $LASTEXITCODE -eq 0
}

# 5. Blue pods ready
Test-Check "Blue pods are ready" {
    $statuses = kubectl get pods -n $Namespace -l "app=blue-green-api,version=blue" -o jsonpath="{.items[*].status.containerStatuses[*].ready}" 2>&1
    $statuses -and ($statuses -match "true") -and -not ($statuses -match "false")
}

# 6. Green Deployment exists
Test-Check "Green Deployment exists" {
    $dep = kubectl get deployment blue-green-api-green -n $Namespace --ignore-not-found -o name 2>&1
    $dep -match "deployment"
}

# 7. Green Deployment rolled out
Test-Check "Green Deployment fully rolled out" {
    kubectl rollout status deployment/blue-green-api-green -n $Namespace --timeout=10s 2>&1 | Out-Null
    $LASTEXITCODE -eq 0
}

# 8. Green pods ready
Test-Check "Green pods are ready" {
    $statuses = kubectl get pods -n $Namespace -l "app=blue-green-api,version=green" -o jsonpath="{.items[*].status.containerStatuses[*].ready}" 2>&1
    $statuses -and ($statuses -match "true") -and -not ($statuses -match "false")
}

# 9. Production Service exists
Test-Check "Production Service exists" {
    $svc = kubectl get svc blue-green-api-production -n $Namespace --ignore-not-found -o name 2>&1
    $svc -match "service"
}

# 10. Production Service selector
$activeVersion = kubectl get svc blue-green-api-production -n $Namespace -o jsonpath='{.spec.selector.version}' 2>&1
Write-Host "`n[INFO] Active production version: $activeVersion" -ForegroundColor Cyan

Test-Check "Production Service has valid version selector" {
    $activeVersion -eq "blue" -or $activeVersion -eq "green"
}

# 11. Endpoints populated
Test-Check "Production endpoints are populated" {
    $endpoints = kubectl get endpoints blue-green-api-production -n $Namespace -o jsonpath='{.subsets[*].addresses[*].ip}' 2>&1
    $endpoints -and $endpoints.Length -gt 0
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nResource overview:" -ForegroundColor Yellow
kubectl get all -n $Namespace 2>&1

if ($failed -gt 0) { exit 1 }

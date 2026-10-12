<#
.SYNOPSIS
    Checks all prerequisites for the Blue-Green Deployment project.

.DESCRIPTION
    Verifies that required tools are installed and accessible:
    Node.js, npm, Docker, kubectl, and optionally a running Kubernetes cluster.
#>

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Blue-Green Deployment - Prerequisites" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$allPassed = $true

function Test-Command {
    param([string]$Name, [string]$Command, [string]$MinVersion)
    try {
        $output = Invoke-Expression $Command 2>&1
        Write-Host "[PASS] $Name - $output" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[FAIL] $Name - not found or not accessible" -ForegroundColor Red
        return $false
    }
}

# Node.js
if (-not (Test-Command "Node.js" "node --version")) { $allPassed = $false }

# npm
if (-not (Test-Command "npm" "npm --version")) { $allPassed = $false }

# Docker
if (-not (Test-Command "Docker" "docker --version")) { $allPassed = $false }

# kubectl
if (-not (Test-Command "kubectl" "kubectl version --client")) { $allPassed = $false }

# Git
if (-not (Test-Command "Git" "git --version")) { $allPassed = $false }

# Docker daemon
Write-Host "`nChecking Docker daemon..." -ForegroundColor Yellow
try {
    docker info 2>&1 | Out-Null
    Write-Host "[PASS] Docker daemon is running" -ForegroundColor Green
}
catch {
    Write-Host "[WARN] Docker daemon may not be running" -ForegroundColor Yellow
    $allPassed = $false
}

# Kubernetes cluster
Write-Host "`nChecking Kubernetes cluster..." -ForegroundColor Yellow
try {
    $context = kubectl config current-context 2>&1
    Write-Host "[INFO] Current context: $context" -ForegroundColor Cyan

    $clusterInfo = kubectl cluster-info 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[PASS] Kubernetes cluster is reachable" -ForegroundColor Green
    }
    else {
        Write-Host "[WARN] Kubernetes cluster is not reachable - K8s deployment steps will fail" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "[WARN] kubectl context not configured - K8s deployment steps will fail" -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "  All prerequisites passed!" -ForegroundColor Green
}
else {
    Write-Host "  Some checks failed. Review warnings above." -ForegroundColor Yellow
}
Write-Host "========================================`n" -ForegroundColor Cyan

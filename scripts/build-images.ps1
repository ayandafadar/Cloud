<#
.SYNOPSIS
    Builds Docker images for Blue (v1.0.0) and Green (v2.0.0).

.DESCRIPTION
    Builds two tagged Docker images from the same Dockerfile,
    differentiated only by their tags.  The APP_VERSION and APP_ENV
    environment variables are set at runtime (in the K8s manifests
    or docker-compose), not baked into the image.
#>

$ErrorActionPreference = "Stop"

$ImageName = "deployshift-api"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Building Docker Images" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Build v1.0.0 (Blue)
Write-Host "Building $ImageName`:v1.0.0 (Blue)..." -ForegroundColor Yellow
docker build -t "${ImageName}:v1.0.0" .
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Failed to build Blue image" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Blue image built: ${ImageName}:v1.0.0" -ForegroundColor Green

# Build v2.0.0 (Green)
Write-Host "`nBuilding $ImageName`:v2.0.0 (Green)..." -ForegroundColor Yellow
docker build -t "${ImageName}:v2.0.0" .
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Failed to build Green image" -ForegroundColor Red
    exit 1
}
Write-Host "[PASS] Green image built: ${ImageName}:v2.0.0" -ForegroundColor Green

# Verify
Write-Host "`nBuilt images:" -ForegroundColor Cyan
docker images $ImageName --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# If desktop-control-plane container is running, import images into its containerd k8s.io namespace
$controlPlane = docker ps --filter "name=desktop-control-plane" --format "{{.Names}}" 2>&1
if ($controlPlane -match "desktop-control-plane") {
    Write-Host "`nSyncing images to Kubernetes control-plane containerd..." -ForegroundColor Yellow
    docker save -o v1-temp.tar "${ImageName}:v1.0.0"
    cmd.exe /c "docker exec -i desktop-control-plane ctr --namespace k8s.io images import - < v1-temp.tar"
    Remove-Item v1-temp.tar -Force -ErrorAction SilentlyContinue

    docker save -o v2-temp.tar "${ImageName}:v2.0.0"
    cmd.exe /c "docker exec -i desktop-control-plane ctr --namespace k8s.io images import - < v2-temp.tar"
    Remove-Item v2-temp.tar -Force -ErrorAction SilentlyContinue
    Write-Host "[PASS] Images imported into Kubernetes node containerd" -ForegroundColor Green
}

Write-Host "`n[DONE] Both images built successfully.`n" -ForegroundColor Green


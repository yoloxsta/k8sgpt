# K8sGPT Lab - Environment Cleanup Script (Windows)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "K8sGPT Lab - Cleanup Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Ask for confirmation
$response = Read-Host "This will delete the kind cluster and clean up resources. Continue? (Y/N)"
if ($response -ne 'Y' -and $response -ne 'y') {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 0
}

# Delete kind cluster
Write-Host ""
Write-Host "Deleting kind cluster..." -ForegroundColor Yellow
$existingClusters = kind get clusters 2>&1
if ($existingClusters -contains "k8sgpt-lab") {
    kind delete cluster --name k8sgpt-lab
    Write-Host "Cluster deleted." -ForegroundColor Green
} else {
    Write-Host "No k8sgpt-lab cluster found." -ForegroundColor Yellow
}

# Remove K8sGPT auth
Write-Host ""
Write-Host "Removing K8sGPT configuration..." -ForegroundColor Yellow
if (Get-Command k8sgpt -ErrorAction SilentlyContinue) {
    k8sgpt auth remove --backend azureopenai 2>$null
    Write-Host "K8sGPT auth removed." -ForegroundColor Green
}

# Clean up any orphaned Docker resources
Write-Host ""
Write-Host "Cleaning up Docker resources..." -ForegroundColor Yellow
docker system prune -f

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To recreate the environment, run:" -ForegroundColor Yellow
Write-Host "  .\scripts\create-cluster.ps1" -ForegroundColor White
Write-Host "  .\scripts\setup-k8sgpt.ps1" -ForegroundColor White
Write-Host ""

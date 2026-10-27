# K8sGPT Lab - Azure VM Setup Script for Windows
# This script installs Docker Desktop, kind, kubectl, and K8sGPT on Windows

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "K8sGPT Lab - Azure VM Setup (Windows)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run PowerShell as Administrator" -ForegroundColor Red
    exit 1
}

# Function to check if a command exists
function Test-Command {
    param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) { return $true }
    }
    catch { return $false }
    finally { $ErrorActionPreference = $oldPreference }
}

# 1. Install Chocolatey (package manager)
Write-Host "[1/5] Checking Chocolatey..." -ForegroundColor Yellow
if (-not (Test-Command choco)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
} else {
    Write-Host "Chocolatey already installed" -ForegroundColor Green
}

# 2. Install Docker Desktop
Write-Host "[2/5] Checking Docker Desktop..." -ForegroundColor Yellow
if (-not (Test-Command docker)) {
    Write-Host "Installing Docker Desktop..." -ForegroundColor Yellow
    Write-Host "This may take several minutes..." -ForegroundColor Gray
    choco install docker-desktop -y
    Write-Host ""
    Write-Host "IMPORTANT: Docker Desktop requires a system restart after installation." -ForegroundColor Yellow
    Write-Host "Please restart your computer and run this script again to continue." -ForegroundColor Yellow
    Write-Host ""
    $restart = Read-Host "Do you want to restart now? (Y/N)"
    if ($restart -eq 'Y' -or $restart -eq 'y') {
        Restart-Computer -Force
    }
    exit 0
} else {
    Write-Host "Docker already installed: $(docker --version)" -ForegroundColor Green
}

# 3. Install kubectl
Write-Host "[3/5] Checking kubectl..." -ForegroundColor Yellow
if (-not (Test-Command kubectl)) {
    Write-Host "Installing kubectl..." -ForegroundColor Yellow
    choco install kubernetes-cli -y
    refreshenv
    
    # Enable tab completion
    kubectl completion powershell | Out-File -Append -Encoding utf8 $PROFILE
} else {
    Write-Host "kubectl already installed: $(kubectl version --client --short)" -ForegroundColor Green
}

# 4. Install kind
Write-Host "[4/5] Checking kind..." -ForegroundColor Yellow
if (-not (Test-Command kind)) {
    Write-Host "Installing kind..." -ForegroundColor Yellow
    choco install kind -y
    refreshenv
} else {
    Write-Host "kind already installed: $(kind version)" -ForegroundColor Green
}

# 5. Install K8sGPT
Write-Host "[5/5] Checking K8sGPT..." -ForegroundColor Yellow
if (-not (Test-Command k8sgpt)) {
    Write-Host "Installing K8sGPT..." -ForegroundColor Yellow
    
    # Download latest K8sGPT release for Windows
    $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/k8sgpt-ai/k8sgpt/releases/latest"
    $downloadUrl = ($latestRelease.assets | Where-Object { $_.name -like "*windows_amd64.zip" }).browser_download_url
    
    $outputPath = "$env:TEMP\k8sgpt.zip"
    $extractPath = "$env:TEMP\k8sgpt"
    
    Write-Host "Downloading from: $downloadUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath
    
    # Extract
    Expand-Archive -Path $outputPath -DestinationPath $extractPath -Force
    
    # Move to system path
    Move-Item -Path "$extractPath\k8sgpt.exe" -Destination "C:\Windows\System32\k8sgpt.exe" -Force
    
    # Cleanup
    Remove-Item -Path $outputPath -Force
    Remove-Item -Path $extractPath -Recurse -Force
    
    # Enable tab completion
    k8sgpt completion powershell | Out-File -Append -Encoding utf8 $PROFILE
} else {
    Write-Host "K8sGPT already installed: $(k8sgpt version)" -ForegroundColor Green
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installed versions:" -ForegroundColor White
Write-Host "  Docker:   $(docker --version)" -ForegroundColor White
Write-Host "  kubectl:  $(kubectl version --client --short)" -ForegroundColor White
Write-Host "  kind:     $(kind version)" -ForegroundColor White
Write-Host "  k8sgpt:   $(k8sgpt version)" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Ensure Docker Desktop is running" -ForegroundColor White
Write-Host "2. Create kind cluster: .\scripts\create-cluster.ps1" -ForegroundColor White
Write-Host "3. Configure K8sGPT with Azure OpenAI: Edit config\k8sgpt-config.yaml" -ForegroundColor White
Write-Host "4. Initialize K8sGPT: .\scripts\setup-k8sgpt.ps1" -ForegroundColor White
Write-Host ""

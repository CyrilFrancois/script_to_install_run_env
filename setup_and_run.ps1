# --- CONFIGURATION ---
$REPO_URL = "https://github.com/YOUR_USERNAME/YOUR_REPO.git"
$PROJECT_DIR = "$HOME\Documents\MyITProject"

# --- 1. PREREQUISITE CHECKS ---

Write-Host "Checking system requirements..." -ForegroundColor Cyan

# Check for Git
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is missing. Downloading installer..." -ForegroundColor Yellow
    Start-BitsTransfer -Source "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe" -Destination "$env:TEMP\git_setup.exe"
    Write-Host "Please follow the Git installation prompts."
    Start-Process -FilePath "$env:TEMP\git_setup.exe" -Wait
}

# Check for Docker
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker Desktop is missing." -ForegroundColor Red
    Write-Host "Please download and install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    Write-Host "Restart this script after installation."
    pause
    exit
}

# Ensure Docker is actually running
while (!(docker info -f '{{.ServerVersion}}' 2>$null)) {
    Write-Host "Waiting for Docker Desktop to start..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Start-Sleep -Seconds 15
}

# --- 2. CODE RETRIEVAL ---

if (!(Test-Path -Path $PROJECT_DIR)) {
    Write-Host "Cloning project from GitHub..." -ForegroundColor Cyan
    git clone $REPO_URL $PROJECT_DIR
} else {
    Write-Host "Updating existing project code..." -ForegroundColor Cyan
    Set-Location $PROJECT_DIR
    git pull
}

# --- 3. EXECUTION ---

Set-Location $PROJECT_DIR

Write-Host "Launching containers..." -ForegroundColor Green
# -d runs in background, but we will follow with logs
docker-compose up -d --build

Write-Host "Application is starting. Displaying logs (Press Ctrl+C to stop logs):" -ForegroundColor White
docker-compose logs -f
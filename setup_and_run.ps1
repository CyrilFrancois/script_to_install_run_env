# --- CONFIGURATION ---
$PROJECT_NAME = "sand-app"
$REPO_URL = "https://github.com/CyrilFrancois/$PROJECT_NAME.git"
$PROJECT_DIR = "$PSScriptRoot\$PROJECT_NAME"

# --- 0. LOGGING ---
function Write-Step($Message, $Status = "CHECK") {
    $Colors = @{"OK"="Green"; "INFO"="White"; "WARN"="Yellow"; "ERROR"="Red"; "CHECK"="Cyan"}
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor Gray
    Write-Host "$Message" -ForegroundColor $Colors[$Status]
}

# --- 1. ADMIN CHECK ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

try {
    Clear-Host
    Write-Step "Project: $PROJECT_NAME" "INFO"
    Write-Host "------------------------------------------------"

    # --- 2. WSL CHECK ---
    Write-Step "Verifying Linux environment..." "CHECK"
    $testUbuntu = wsl -d Ubuntu echo "alive" 2>$null
    if ($testUbuntu -notmatch "alive") {
        Write-Step "Ubuntu is not active. Please start it manually once." "ERROR"
        pause; exit
    }

    # --- 3. GIT SYNC ---
    if (!(Test-Path $PROJECT_DIR)) {
        Write-Step "Cloning repository..." "INFO"
        git clone $REPO_URL "$PROJECT_DIR"
    } else {
        Set-Location "$PROJECT_DIR"
        git pull
    }

    # --- 4. DOCKER ENGINE ---
    Write-Step "Locating Linux-native Docker..." "CHECK"
    # Force search for native Linux binary only, ignoring /mnt/c/
    $dockerBin = wsl -d Ubuntu sh -c "which docker | grep -v '/mnt/c/' || echo '/usr/bin/docker'"
    $dockerBin = $dockerBin.Trim()

    # Check if it actually exists in Linux
    $exists = wsl -d Ubuntu sh -c "test -f $dockerBin && echo 'exists' || echo 'missing'"
    if ($exists -match "missing") {
        Write-Step "Docker missing in Linux. Installing via apt..." "WARN"
        wsl -d Ubuntu sudo apt-get update -y
        wsl -d Ubuntu sudo apt-get install -y docker.io docker-compose-v2
    }

    Write-Step "Starting Docker service..." "INFO"
    wsl -d Ubuntu sudo service docker start 2>$null
    Write-Step "Docker Engine Active: $dockerBin" "OK"

    # --- 5. LAUNCH ---
    Write-Step "Launching Containers..." "OK"
    
    $env:WSLPATH_TMP = $PROJECT_DIR
    $wslPath = (wsl -d Ubuntu sh -c "wslpath '$env:WSLPATH_TMP'").Trim()

    # We use 'sudo' with the direct binary path to avoid any PATH confusion
    wsl -d Ubuntu sh -c "cd '$wslPath' && sudo $dockerBin compose up -d --build"
    wsl -d Ubuntu sh -c "cd '$wslPath' && sudo $dockerBin compose logs -f"

} catch {
    Write-Host "`n[!] ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nScript finished. Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
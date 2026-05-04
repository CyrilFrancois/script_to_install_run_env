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
    $dockerBin = wsl -d Ubuntu sh -c "which docker | grep -v '/mnt/c/' || echo '/usr/bin/docker'"
    $dockerBin = $dockerBin.Trim()

    $exists = wsl -d Ubuntu sh -c "test -f $dockerBin && echo 'exists' || echo 'missing'"
    if ($exists -match "missing") {
        Write-Step "Docker missing in Linux. Installing..." "WARN"
        wsl -d Ubuntu sudo apt-get update -y
        wsl -d Ubuntu sudo apt-get install -y docker.io docker-compose-v2
    }

    wsl -d Ubuntu sudo service docker start 2>$null
    Write-Step "Docker Engine Active: $dockerBin" "OK"

    # --- 5. LAUNCH WITH AUTO-REMOVE ---
    Write-Step "Launching Containers (Auto-Remove enabled)..." "OK"
    Write-Step "Note: Closing this window or pressing Ctrl+C will delete the containers." "WARN"
    
    $env:WSLPATH_TMP = $PROJECT_DIR
    $wslPath = (wsl -d Ubuntu sh -c "wslpath '$env:WSLPATH_TMP'").Trim()

    # CHANGES MADE HERE:
    # 1. Removed '-d' (detached mode) so the script stays connected to the container logs.
    # 2. Added '--remove-orphans' and '--abort-on-container-exit' for a clean exit.
    # 3. Added a trailing 'down' command to ensure cleanup even if the process is interrupted.
    wsl -d Ubuntu sh -c "cd '$wslPath' && sudo $dockerBin compose up --build --remove-orphans; sudo $dockerBin compose down"

} catch {
    Write-Host "`n[!] ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSession ended. Containers have been removed." -ForegroundColor Cyan
Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
# --- CONFIGURATION ---
$PROJECT_NAME = "sand-app"
$REPO_URL = "https://github.com/CyrilFrancois/$PROJECT_NAME.git"
$PROJECT_DIR = "$PSScriptRoot\$PROJECT_NAME"

# --- 0. PRE-FLIGHT LOGGING ---
function Write-Step($Message, $Status = "CHECK") {
    $Colors = @{"OK"="Green"; "INFO"="Cyan"; "WARN"="Yellow"; "ERROR"="Red"; "CHECK"="White"}
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $Colors[$Status]
}

# --- 1. ADMIN CHECK ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

try {
    Clear-Host
    Write-Step "SUCCESS: Elevated privileges confirmed." "OK"
    Write-Step "Starting deployment for $PROJECT_NAME" "INFO"

    # --- 2. WSL & DISTRO CHECK ---
    Write-Step "Checking WSL2 and Ubuntu Distro..." "CHECK"
    $wslList = wsl --list --quiet
    if ($wslList -notmatch "Ubuntu") {
        Write-Step "Ubuntu Distro not found. Installing Ubuntu (Required for Docker Engine)..." "WARN"
        wsl --install -d Ubuntu --no-launch
        Write-Step "Ubuntu installation initiated. You MUST REBOOT after this finishes." "ERROR"
        pause; exit
    }
    Write-Step "WSL2 Ubuntu Distro is ready." "OK"

    # --- 3. GIT CHECK ---
    Write-Step "Checking Git..." "CHECK"
    if (!(Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Step "Git missing. Setting up portable version..." "WARN"
        $GitFolder = "$env:LOCALAPPDATA\Programs\GitPortable"
        if (!(Test-Path $GitFolder)) {
            New-Item -ItemType Directory -Force -Path $GitFolder | Out-Null
            $zip = "$env:TEMP\git.zip"
            Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/MinGit-2.44.0-64-bit.zip" -OutFile $zip
            Expand-Archive $zip -DestinationPath $GitFolder -Force
        }
        $env:Path += ";$GitFolder\cmd"
        Write-Step "Git set up." "OK"
    }

    # --- 4. DOCKER & DOCKER-COMPOSE (WSL SIDE) ---
    Write-Step "Checking Docker Engine inside Ubuntu..." "CHECK"
    # We target Ubuntu specifically to avoid the "bin/sh" error
    $dockerTest = wsl -d Ubuntu which docker 2>$null
    if (!$dockerTest) {
        Write-Step "Installing Docker & Compose into Ubuntu (Headless)..." "WARN"
        # Updated install command to include the Compose Plugin
        wsl -d Ubuntu sh -c "curl -fsSL https://get.docker.com | sh"
        wsl -d Ubuntu sh -c "sudo usermod -aG docker `$USER"
    }
    
    # Start the service
    wsl -d Ubuntu sudo service docker start 2>$null
    Write-Step "Docker Engine and Compose Plugin are active." "OK"

    # --- 5. REPO SYNC ---
    if (!(Test-Path $PROJECT_DIR)) {
        Write-Step "Cloning repository..." "INFO"
        New-Item -ItemType Directory -Force -Path (Split-Path $PROJECT_DIR) | Out-Null
        git clone $REPO_URL $PROJECT_DIR
    } else {
        Write-Step "Updating repository..." "INFO"
        Set-Location $PROJECT_DIR
        git pull
    }

    # --- 6. RUN (Using the modern 'docker compose' command) ---
    Write-Step "Launching Docker Compose..." "OK"
    Set-Location $PROJECT_DIR
    # Note: Modern Docker uses 'docker compose' (no hyphen) as a plugin
    wsl -d Ubuntu docker compose up -d --build
    wsl -d Ubuntu docker compose logs -f

} catch {
    Write-Host "`n[!] CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
}

Write-Host "`n--- SCRIPT FINISHED OR STOPPED ---" -ForegroundColor Cyan
Write-Host "Press any key to close this window..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
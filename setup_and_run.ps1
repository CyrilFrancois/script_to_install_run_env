# --- CONFIGURATION ---
$PROJECT_NAME = "sand-app"
$REPO_URL = "https://github.com/CyrilFrancois/$PROJECT_NAME.git"
$PROJECT_DIR = "$PSScriptRoot\$PROJECT_NAME"

# --- 0. SIMPLE LOGGING ---
function Write-Step($Message, $Status = "CHECK") {
    $Colors = @{
        "OK"    = "Green"
        "INFO"  = "White"
        "WARN"  = "Yellow"
        "ERROR" = "Red"
        "CHECK" = "Cyan"
    }
    $Time = Get-Date -Format "HH:mm:ss"
    Write-Host "[$Time] " -NoNewline -ForegroundColor Gray
    Write-Host "$Message" -ForegroundColor $Colors[$Status]
}

# --- 1. ADMIN CHECK ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit -NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# --- 2. MAIN EXECUTION ---
try {
    Clear-Host
    Write-Step "Project: $PROJECT_NAME" "INFO"
    Write-Step "Path: $PROJECT_DIR" "INFO"
    Write-Host "------------------------------------------------"

    # --- WSL & UBUNTU CHECK ---
    Write-Step "Checking Linux Environment..." "CHECK"
    $testUbuntu = wsl -d Ubuntu echo "alive" 2>$null
    if ($testUbuntu -match "alive") {
        Write-Step "Linux environment (Ubuntu) is verified." "OK"
    } else {
        Write-Step "Ubuntu not responding. Attempting to wake/install..." "WARN"
        wsl --install -d Ubuntu --no-launch 2>$null
        Start-Sleep -Seconds 5
    }

    # --- GIT CHECK ---
    Write-Step "Checking Git..." "CHECK"
    if (!(Get-Command git -ErrorAction SilentlyContinue)) {
        $GitFolder = "$env:LOCALAPPDATA\Programs\GitPortable"
        if (!(Test-Path $GitFolder)) {
            New-Item -ItemType Directory -Force -Path $GitFolder | Out-Null
            $zip = "$env:TEMP\git.zip"
            Write-Step "Downloading Git..." "INFO"
            Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/MinGit-2.44.0-64-bit.zip" -OutFile $zip -ProgressAction Continue
            Expand-Archive $zip -DestinationPath $GitFolder -Force
        }
        $env:Path += ";$GitFolder\cmd"
        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$GitFolder\cmd", "Process")
    }
    Write-Step "Git is ready." "OK"

    # --- DOCKER ENGINE RECOVERY ---
    Write-Step "Verifying Docker installation..." "CHECK"
    # Check for docker binary anywhere in the path
    $dockerCheck = wsl -d Ubuntu sh -c "command -v docker" 2>$null
    
    if ([string]::IsNullOrWhiteSpace($dockerCheck)) {
        Write-Step "Docker missing. Running deep installation..." "WARN"
        # Download and run the official docker install script, then ensure the symlink is in /usr/bin
        wsl -d Ubuntu sh -c "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
        wsl -d Ubuntu sh -c "sudo ln -s /usr/local/bin/docker /usr/bin/docker" 2>$null
    }

    Write-Step "Starting Docker service..." "INFO"
    wsl -d Ubuntu sudo service docker start 2>$null
    Write-Step "Docker Engine is active." "OK"

    # --- REPO SYNC ---
    if (!(Test-Path $PROJECT_DIR)) {
        Write-Step "Cloning repository..." "INFO"
        git clone $REPO_URL "$PROJECT_DIR"
    } else {
        Write-Step "Updating code..." "INFO"
        Set-Location "$PROJECT_DIR"
        git pull
    }

    # --- LAUNCH ---
    Write-Step "Starting Containers..." "OK"
    
    # Use environment variable to safely bridge the Windows path to WSL
    $env:WSLPATH_TMP = $PROJECT_DIR
    $wslPath = wsl -d Ubuntu sh -c "wslpath '$env:WSLPATH_TMP'"
    
    # Run compose using the most likely binary location
    wsl -d Ubuntu sh -c "cd '$wslPath' && sudo docker compose up -d --build"
    wsl -d Ubuntu sh -c "cd '$wslPath' && sudo docker compose logs -f"

} catch {
    Write-Host "`n[!] ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
}

Write-Host "`nScript finished. Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
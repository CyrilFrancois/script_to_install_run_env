# Project Setup & Execution Guide

This document explains how to set up and run the application on a Windows machine. Follow these instructions to install the necessary tools and launch the project using the provided automation script.

## 1. Prerequisites
The application requires the following software to be installed:
* **Git for Windows**: To download and update the code.
* **Docker Desktop**: To run the backend and frontend containers.
* **WSL 2 (Windows Subsystem for Linux)**: Required by Docker Desktop.

## 2. Initial Setup
The provided automation script handles the environment check and code retrieval.

### Manual Installation (If script fails)
If the script cannot automatically install a component, download them here:
- Git: [https://git-scm.com/download/win](https://git-scm.com/download/win)
- Docker Desktop: [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)

## 3. How to Run
1.  **Download the Scripts**: Ensure `run_app.bat` and `setup_and_run.ps1` are in the same folder.
2.  **Launch**: Double-click the `run_app.bat` file.
3.  **Wait**: The script will check for Git and Docker, clone the project from GitHub, and start the containers.
4.  **Access**: Once the logs appear, your application is running.

## 4. Automation Files

### PowerShell Script (setup_and_run.ps1)
"
# --- CONFIGURATION ---
$REPO_URL = "https://github.com/YOUR_USERNAME/YOUR_REPO.git"
$PROJECT_DIR = "$HOME\Documents\MyITProject"

# --- 1. PREREQUISITE CHECKS ---
Write-Host "Checking system requirements..." -ForegroundColor Cyan

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git is missing. Downloading installer..." -ForegroundColor Yellow
    Start-BitsTransfer -Source "https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe" -Destination "$env:TEMP\git_setup.exe"
    Start-Process -FilePath "$env:TEMP\git_setup.exe" -Wait
}

if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker Desktop is missing. Please install it from https://www.docker.com/products/docker-desktop" -ForegroundColor Red
    pause
    exit
}

while (!(docker info -f '{{.ServerVersion}}' 2>$null)) {
    Write-Host "Waiting for Docker Desktop to start..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    Start-Sleep -Seconds 15
}

# --- 2. CODE RETRIEVAL ---
if (!(Test-Path -Path $PROJECT_DIR)) {
    Write-Host "Cloning project..." -ForegroundColor Cyan
    git clone $REPO_URL $PROJECT_DIR
} else {
    Write-Host "Updating code..." -ForegroundColor Cyan
    Set-Location $PROJECT_DIR
    git pull
}

# --- 3. EXECUTION ---
Set-Location $PROJECT_DIR
Write-Host "Launching containers..." -ForegroundColor Green
docker-compose up -d --build
docker-compose logs -f
"

### Batch Wrapper (run_app.bat)
"
@echo off
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_and_run.ps1"
pause
"
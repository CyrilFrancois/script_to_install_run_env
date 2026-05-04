@echo off
REM We use -NoExit so the window stays open even if PowerShell crashes
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoExit -NoProfile -ExecutionPolicy Bypass -File ""%~dp0setup_and_run.ps1""'"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to launch PowerShell.
    pause
)
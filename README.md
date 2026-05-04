# Project Setup & Execution Guide

This document explains how to set up and run the application on a Windows machine. Follow these instructions to install the necessary tools and launch the project using the provided automation script.

## 1. Prerequisites
The application will install the following software:
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
2.  **Setup**: Fill the line with the approprate project name in the .ps1 file: $PROJECT_NAME = "MyAwesomeProject".
3.  **Launch**: Double-click the `run_app.bat` file.
4.  **Wait**: The script will check for Git and Docker, clone the project from GitHub, and start the containers.
5.  **Access**: Once the logs appear, your application is running.
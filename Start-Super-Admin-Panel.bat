@echo off
setlocal
title Strolla Health - Super Admin Panel
cd /d "%~dp0strola_health_super_admin_next"

echo ============================================
echo   Strolla Health - Super Admin Panel
echo ============================================
echo.

where node >nul 2>nul
if errorlevel 1 (
    echo Node.js was not found on this computer.
    echo Please install it from https://nodejs.org ^(the LTS version^), then run this file again.
    echo.
    pause
    exit /b 1
)

if not exist ".env.local" (
    echo Creating local config...
    > ".env.local" (
        echo NEXT_PUBLIC_MOCK_MODE=true
        echo NEXT_PUBLIC_MOCK_DEFAULT_ROLE=super_admin
    )
)

if not exist "node_modules" (
    echo First-time setup - installing dependencies, this can take a few minutes...
    call npm install
    if errorlevel 1 (
        echo.
        echo Something went wrong during setup. Please send a screenshot of this window.
        pause
        exit /b 1
    )
)

echo Starting the super admin panel server...
start "Strolla Super Admin Panel - Server (keep this window open)" cmd /k "npm run dev"

echo Waiting for the server to be ready...
timeout /t 8 /nobreak >nul

start "" "http://localhost:3200"

echo.
echo The super admin panel should now be open in your browser at http://localhost:3200
echo On the sign-in page, click "Skip - continue as demo staff", or enter any email/password.
echo.
echo To stop the panel, close the other black window titled
echo "Strolla Super Admin Panel - Server".
echo.
pause

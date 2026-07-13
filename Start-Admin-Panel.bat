@echo off
setlocal
title Strolla Health - Admin Panel
cd /d "%~dp0strola_health_admin_next"

echo ============================================
echo   Strolla Health - Admin Panel
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
    > ".env.local" echo NEXT_PUBLIC_MOCK_MODE=true
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

echo Starting the admin panel server...
start "Strolla Admin Panel - Server (keep this window open)" cmd /k "npm run dev"

echo Waiting for the server to be ready...
timeout /t 8 /nobreak >nul

start "" "http://localhost:3100"

echo.
echo The admin panel should now be open in your browser at http://localhost:3100
echo On the sign-in page, click "Skip - continue as demo staff", or enter any email/password.
echo.
echo To stop the admin panel, close the other black window titled
echo "Strolla Admin Panel - Server".
echo.
pause

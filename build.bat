@echo off
title fuelle -- Windows Build

echo.
echo  fuelle v0.5.0 - Windows Build
echo  ================================
echo.

:: Check for node
node --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Node.js is not installed.
    echo.
    echo  Please install it from:
    echo    https://nodejs.org/en/download
    echo.
    echo  Then run this build.bat again.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('node --version') do set "NODE_VER=%%v"
for /f "tokens=*" %%v in ('npm --version') do set "NPM_VER=%%v"
echo [1/3] Node.js %NODE_VER% / npm v%NPM_VER% found.
echo.

echo [2/3] Installing dependencies...
call npm install
if errorlevel 1 (
    echo  [ERROR] npm install failed.
    pause
    exit /b 1
)
echo.

echo [3/3] Building Windows .exe...
call npm run build:win
if errorlevel 1 (
    echo  [ERROR] Build failed.
    pause
    exit /b 1
)

echo.
echo  Done! Output: dist-electron\fuelle Setup 0.5.0.exe
echo.
explorer dist-electron 2>nul
pause

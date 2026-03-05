@echo off
setlocal
cd /d "%~dp0"
set VERSION=0.5.0-alpha
title Fuelle v%VERSION% - Build All

echo ==========================================
echo   Fuelle v%VERSION% - Build All Platforms
echo   Windows EXE + Android APK
echo ==========================================
echo.

:: [1/5] Dependencies
echo [1/5] Getting dependencies...
call flutter pub get
if errorlevel 1 ( echo [FAIL] flutter pub get failed & pause & exit /b 1 )
echo [OK] Dependencies ready.
echo.

:: [2/5] Icons
echo [2/5] Setting up platforms and injecting icons...
call inject_icons.bat
echo.

:: [3/5] Windows build
echo [3/5] Building Windows release...
call flutter build windows --release
if errorlevel 1 (
  echo ==========================================
  echo   BUILD FAILED - see errors above
  echo ==========================================
  pause & exit /b 1
)

mkdir installers 2>nul
set EXE_PATH=build\windows\x64\runner\Release
set EXE_FOUND=0
if exist "%EXE_PATH%\fuelle.exe" set EXE_FOUND=1

if "%EXE_FOUND%"=="0" (
  echo [WARN] fuelle.exe not found at expected path
) else (
  echo [OK] Windows EXE built: %EXE_PATH%\fuelle.exe
)

:: NSIS installer (optional)
where makensis >nul 2>&1
if not errorlevel 1 (
  if exist "fuelle_setup.nsi" (
    makensis fuelle_setup.nsi
    if exist "installers\fuelle_%VERSION%_setup.exe" (
      echo [OK] Installer: installers\fuelle_%VERSION%_setup.exe
    )
  )
) else (
  echo [INFO] NSIS not found - skipping installer. Install NSIS to generate .exe installer.
)
echo.

:: [4/5] Android build
echo [4/5] Building Android APK...
call flutter build apk --release
if errorlevel 1 (
  echo [WARN] Android build failed - continuing
) else (
  if exist "build\app\outputs\flutter-apk\app-release.apk" (
    copy /Y "build\app\outputs\flutter-apk\app-release.apk" "installers\fuelle_%VERSION%.apk" >nul
    echo [OK] Android APK: installers\fuelle_%VERSION%.apk
  )
)
echo.

:: [5/5] Summary
echo [5/5] Build summary
echo ==========================================
echo   Fuelle v%VERSION% - Build Complete
echo ==========================================
if exist "installers\fuelle_%VERSION%_setup.exe" echo   Installer : installers\fuelle_%VERSION%_setup.exe
if exist "%EXE_PATH%\fuelle.exe"                 echo   Windows   : %EXE_PATH%\fuelle.exe
if exist "installers\fuelle_%VERSION%.apk"       echo   Android   : installers\fuelle_%VERSION%.apk
echo.
pause

@echo off
title fuelle -- Android APK Build

echo.
echo  fuelle - Android APK Builder
echo  ==============================
echo.

:: ── Check Node.js ─────────────────────────────────────────────────────────────
node --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Node.js is not installed.
    echo.
    echo  Install from: https://nodejs.org/en/download
    echo  Then re-run this script.
    echo.
    pause & exit /b 1
)

:: ── Check Java ────────────────────────────────────────────────────────────────
java -version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Java is not installed.
    echo.
    echo  Install Java 17 from: https://adoptium.net
    echo  Choose: Temurin 17 - Windows x64 Installer
    echo  Then re-run this script.
    echo.
    pause & exit /b 1
)

:: ── Check Android SDK ─────────────────────────────────────────────────────────
if "%ANDROID_HOME%"=="" (
    if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
        set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
    ) else (
        echo  [ERROR] Android SDK not found.
        echo.
        echo  Install Android Studio from: https://developer.android.com/studio
        echo  Open it once to let it install the SDK automatically.
        echo  Then re-run this script.
        echo.
        pause & exit /b 1
    )
)

for /f "tokens=*" %%v in ('node --version') do set "NODE_VER=%%v"
echo [1/4] Node.js %NODE_VER% found.
echo [1/4] Android SDK: %ANDROID_HOME%
echo.

:: ── Install Capacitor deps (run from capacitor-mobile folder) ─────────────────
echo [2/4] Installing Capacitor dependencies...
cd capacitor-mobile
call npm install --silent
if errorlevel 1 (
    echo  [ERROR] npm install failed.
    pause & exit /b 1
)
echo  [OK] Dependencies installed.
echo.

:: ── Sync www into Android ─────────────────────────────────────────────────────
echo [3/4] Syncing app into Android project...
echo       (copies www\index.html + icons into the Android project)
echo.

:: npx cap sync reads capacitor.config.json from the current directory (capacitor-mobile)
:: which points webDir to ../www — so it finds index.html correctly
call npx cap sync android --inline
if errorlevel 1 (
    echo.
    echo  [ERROR] cap sync failed. See above for details.
    pause & exit /b 1
)
echo.

:: ── Build APK ─────────────────────────────────────────────────────────────────
echo [4/4] Building APK...
echo.

cd android
call gradlew.bat assembleDebug 2>&1
if errorlevel 1 (
    echo.
    echo  [ERROR] Gradle build failed. Common fixes:
    echo    - Make sure Java 17+ is installed (not Java 8)
    echo    - Open Android Studio once to complete SDK setup
    echo    - Run: cd capacitor-mobile\android && gradlew.bat --version
    echo      to see a more detailed error
    pause & exit /b 1
)
cd ..\..

:: ── Done ──────────────────────────────────────────────────────────────────────
set "APK=capacitor-mobile\android\app\build\outputs\apk\debug\app-debug.apk"

echo.
echo  Done!
echo.
echo  +----------------------------------------------------------+
echo  ^|  APK: %APK%
echo  ^|                                                          ^|
echo  ^|  To install on Android phone or tablet:                  ^|
echo  ^|    1. Enable "Install from unknown sources" in Settings   ^|
echo  ^|    2. Copy the .apk to your device and tap it            ^|
echo  ^|  OR connect via USB:  adb install %APK%
echo  +----------------------------------------------------------+
echo.

explorer "capacitor-mobile\android\app\build\outputs\apk\debug" 2>nul
pause

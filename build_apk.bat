@echo off
title fuelle -- Android APK Build

echo.
echo  fuelle v0.5.0 - Android APK Builder
echo  =====================================
echo.

:: ── Check Node.js ─────────────────────────────────────────────────────────────
node --version >nul 2>&1
if errorlevel 1 (
    echo  [ERROR] Node.js is not installed.
    echo.
    echo  Install it from: https://nodejs.org/en/download
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

:: ── Check Android SDK / ANDROID_HOME ─────────────────────────────────────────
if "%ANDROID_HOME%"=="" (
    if exist "%LOCALAPPDATA%\Android\Sdk" (
        set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
    ) else (
        echo  [ERROR] Android SDK not found.
        echo.
        echo  Install Android Studio from: https://developer.android.com/studio
        echo  Open it once, it will install the SDK automatically.
        echo  Then re-run this script.
        echo.
        pause & exit /b 1
    )
)

for /f "tokens=*" %%v in ('node --version') do set "NODE_VER=%%v"
for /f "tokens=*" %%v in ('java -version 2^>^&1 ^| findstr version') do set "JAVA_VER=%%v"
echo [1/5] Node.js %NODE_VER% found.
echo [1/5] %JAVA_VER%
echo [1/5] Android SDK: %ANDROID_HOME%
echo.

:: ── Install Capacitor dependencies ───────────────────────────────────────────
echo [2/5] Installing Capacitor dependencies...
cd capacitor-mobile
call npm install
if errorlevel 1 ( echo [ERROR] npm install failed. & pause & exit /b 1 )
echo.

:: ── Sync www into Android project ────────────────────────────────────────────
echo [3/5] Syncing web app into Android...
call npx cap sync android
if errorlevel 1 ( echo [ERROR] cap sync failed. & pause & exit /b 1 )
echo.

:: ── Build debug APK (no keystore needed) ─────────────────────────────────────
echo [4/5] Building APK...
echo       Building debug APK (install on your device directly).
echo.

cd android
call gradlew.bat assembleDebug
if errorlevel 1 (
    echo.
    echo  [ERROR] Gradle build failed.
    echo  Common fixes:
    echo    - Make sure ANDROID_HOME is set to your SDK folder
    echo    - Make sure Java 17 is installed
    echo    - Open Android Studio once to finish SDK setup
    pause & exit /b 1
)
cd ..

:: ── Done ──────────────────────────────────────────────────────────────────────
set "APK_PATH=android\app\build\outputs\apk\debug\app-debug.apk"

echo.
echo [5/5] Done!
echo.
echo  +--------------------------------------------------------------+
echo  ^|  APK: capacitor-mobile\%APK_PATH%  ^|
echo  ^|                                                              ^|
echo  ^|  To install on your Android phone or tablet:                 ^|
echo  ^|    1. Enable "Install from unknown sources" in Settings       ^|
echo  ^|    2. Copy the .apk to your device                           ^|
echo  ^|    3. Open it and tap Install                                 ^|
echo  ^|                                                              ^|
echo  ^|  OR connect your device via USB and run:                     ^|
echo  ^|    adb install %APK_PATH%    ^|
echo  +--------------------------------------------------------------+
echo.

cd ..
explorer "capacitor-mobile\android\app\build\outputs\apk\debug" 2>nul
pause

@echo off
:: Injects Fuelle icons into Windows and Android platform runner folders
cd /d "%~dp0"

echo [+] Injecting platform icons...

:: Windows icon
if exist "assets\app_icon.ico" (
  if exist "windows\runner\resources" (
    copy /Y "assets\app_icon.ico" "windows\runner\resources\app_icon.ico" >nul
    echo [OK] Windows icon injected.
  )
)

:: Android mipmaps
for %%D in (mdpi hdpi xhdpi xxhdpi xxxhdpi) do (
  if exist "assets\android_mipmap-%%D.png" (
    if exist "android\app\src\main\res\mipmap-%%D" (
      copy /Y "assets\android_mipmap-%%D.png" "android\app\src\main\res\mipmap-%%D\ic_launcher.png" >nul
      echo [OK] Android mipmap-%%D icon injected.
    )
  )
)

:: Patch Android package ID
set MANIFEST=android\app\src\main\AndroidManifest.xml
if exist "%MANIFEST%" (
  powershell -Command "(Get-Content '%MANIFEST%') -replace 'com\.example\.fuelle','com.privacychase.fuelle' | Set-Content '%MANIFEST%'"
  echo   [OK] Android package ID patched to com.privacychase.fuelle
)

echo [+] Icons done.

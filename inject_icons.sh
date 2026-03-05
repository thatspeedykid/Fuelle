#!/usr/bin/env bash
# Injects Fuelle icons into all platform runner folders
cd "$(dirname "$0")"

echo "[+] Injecting platform icons..."

# Windows icon
if [ -f "assets/app_icon.ico" ] && [ -d "windows/runner/resources" ]; then
  cp "assets/app_icon.ico" "windows/runner/resources/app_icon.ico"
  echo "[OK] Windows icon injected."
fi

# macOS icon
if [ -f "assets/macos_icon_1024.png" ] && [ -d "macos/Runner/Assets.xcassets" ]; then
  cp "assets/macos_icon_1024.png" "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png" 2>/dev/null || true
  echo "[OK] macOS icon injected."
fi

# iOS icon
if [ -f "assets/ios_icon_1024.png" ] && [ -d "ios/Runner/Assets.xcassets" ]; then
  cp "assets/ios_icon_1024.png" "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" 2>/dev/null || true
  echo "[OK] iOS icon injected."
fi

# Android mipmaps
for DPI in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  SRC="assets/android_mipmap-${DPI}.png"
  DST="android/app/src/main/res/mipmap-${DPI}/ic_launcher.png"
  if [ -f "$SRC" ] && [ -d "$(dirname "$DST")" ]; then
    cp "$SRC" "$DST"
    echo "[OK] Android mipmap-${DPI} icon injected."
  fi
done

# Patch Android package ID (mirrors inject_icons.bat behaviour)
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  sed -i 's/com\.example\.fuelle/com.privacychase.fuelle/g' "$MANIFEST"
  echo "[OK] Android package ID patched to com.privacychase.fuelle"
fi

echo "[+] Icons done."

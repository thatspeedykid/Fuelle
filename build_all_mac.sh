#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
VERSION="0.5.0-alpha"

echo "=========================================="
echo "  Fuelle v$VERSION - Mac Build"
echo "  macOS App + iOS IPA"
echo "=========================================="
echo

echo "[1/4] Getting dependencies..."
flutter pub get
echo "[OK] Dependencies ready."
echo

echo "[2/4] Injecting icons..."
bash inject_icons.sh
echo

echo "[3/4] Building macOS release..."
flutter build macos --release
mkdir -p installers
MACOS_APP="build/macos/Build/Products/Release/fuelle.app"
if [ -d "$MACOS_APP" ]; then
  echo "[OK] macOS app: $MACOS_APP"
  # Create DMG if create-dmg is available
  if command -v create-dmg &>/dev/null; then
    create-dmg \
      --volname "Fuelle $VERSION" \
      --window-pos 200 120 \
      --window-size 600 400 \
      --icon-size 100 \
      --app-drop-link 450 185 \
      "installers/fuelle_${VERSION}.dmg" \
      "$MACOS_APP"
    echo "[OK] DMG: installers/fuelle_${VERSION}.dmg"
  else
    echo "[INFO] create-dmg not found - skipping DMG. Install with: brew install create-dmg"
  fi
else
  echo "[WARN] macOS app not found"
fi
echo

echo "[4/4] Building iOS IPA (requires Xcode + signing)..."
flutter build ipa --release 2>/dev/null && \
  echo "[OK] iOS IPA built" || \
  echo "[INFO] iOS build skipped (requires signing config)"
echo

echo "=========================================="
echo "  Fuelle v$VERSION - Mac Build Complete"
echo "=========================================="

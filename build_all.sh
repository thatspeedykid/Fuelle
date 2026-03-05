#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
VERSION="0.5.0-alpha"

echo "=========================================="
echo "  Fuelle v$VERSION - Build All Platforms"
echo "  Linux + Android"
echo "=========================================="
echo

echo "[1/4] Getting dependencies..."
flutter pub get
echo "[OK] Dependencies ready."
echo

echo "[2/4] Injecting icons..."
bash inject_icons.sh
echo

echo "[3/4] Building Linux release..."
flutter build linux --release
mkdir -p installers
LINUX_BUNDLE="build/linux/x64/release/bundle"
if [ -f "$LINUX_BUNDLE/fuelle" ]; then
  TARBALL="installers/fuelle_${VERSION}_linux_x64.tar.gz"
  tar -czf "$TARBALL" -C "$LINUX_BUNDLE" .
  echo "[OK] Linux bundle: $TARBALL"
else
  echo "[WARN] Linux binary not found at expected path"
fi
echo

echo "[4/4] Building Android APK..."
flutter build apk --release && \
  cp build/app/outputs/flutter-apk/app-release.apk "installers/fuelle_${VERSION}.apk" && \
  echo "[OK] Android APK: installers/fuelle_${VERSION}.apk" || \
  echo "[WARN] Android build failed"
echo

echo "=========================================="
echo "  Fuelle v$VERSION - Build Complete"
echo "=========================================="

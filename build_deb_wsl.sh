#!/usr/bin/env bash
# Builds a .deb package for Linux (run from WSL or Linux)
set -e
cd "$(dirname "$0")"
VERSION="0.5.0-alpha"
DEB_DIR="deb_build/fuelle_${VERSION}"

rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN" \
         "$DEB_DIR/usr/bin" \
         "$DEB_DIR/usr/lib/fuelle" \
         "$DEB_DIR/usr/share/applications" \
         "$DEB_DIR/usr/share/doc/fuelle" \
         "$DEB_DIR/usr/share/icons/hicolor/256x256/apps"

# Build Flutter Linux release first
flutter build linux --release

# Copy bundle
cp -r build/linux/x64/release/bundle/. "$DEB_DIR/usr/lib/fuelle/"

# Rename binary if needed
[ -f "$DEB_DIR/usr/lib/fuelle/flo" ] && mv "$DEB_DIR/usr/lib/fuelle/flo" "$DEB_DIR/usr/lib/fuelle/fuelle"

# Launcher script
cat > "$DEB_DIR/usr/bin/fuelle" << 'LAUNCH'
#!/bin/sh
cd /usr/lib/fuelle && exec ./fuelle "$@"
LAUNCH
chmod +x "$DEB_DIR/usr/bin/fuelle"

# Icon
for sz in 16 32 48 64 128 256 512; do
  src="assets/icon_${sz}.png"
  [ -f "$src" ] && cp "$src" "$DEB_DIR/usr/share/icons/hicolor/${sz}x${sz}/apps/fuelle.png"
done

# Desktop entry
cat > "$DEB_DIR/usr/share/applications/fuelle.desktop" << 'DESK'
[Desktop Entry]
Type=Application
Version=1.0
Name=Fuelle
Comment=Privacy-first meal planner & nutrition tracker
Exec=/usr/bin/fuelle
Icon=fuelle
Terminal=false
Categories=Utility;Health;
StartupWMClass=fuelle
DESK

# Control file
cat > "$DEB_DIR/DEBIAN/control" << CTRL
Package: fuelle
Version: $VERSION
Section: utils
Priority: optional
Architecture: amd64
Maintainer: PrivacyChase <hello@privacychase.com>
Description: fuelle - privacy-first meal planner & nutrition tracker
 No accounts. No tracking. No ads.
 Log meals, track calories and macros, export your data.
CTRL

mkdir -p installers
dpkg-deb --build "$DEB_DIR" "installers/fuelle_${VERSION}_amd64.deb"
echo "[OK] DEB built: installers/fuelle_${VERSION}_amd64.deb"

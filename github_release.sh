#!/usr/bin/env bash
# Fuelle — GitHub Release Script
# Uploads built artifacts to a GitHub release via gh CLI
# Run from the repo root after building all platforms

set -e
cd "$(dirname "$0")"
VERSION="0.5.0-alpha"
TAG="v$VERSION"
REPO="privacychase/fuelle"

echo "=========================================="
echo "  Fuelle $TAG — GitHub Release Script"
echo "=========================================="
echo

# Check gh CLI
if ! command -v gh &>/dev/null; then
  echo "[ERROR] gh CLI not found. Install from: https://cli.github.com"
  exit 1
fi

# Check we're in the right repo
if [ ! -f "pubspec.yaml" ]; then
  echo "[ERROR] Run this from the fuelle repo root (where pubspec.yaml is)"
  exit 1
fi

echo "Repo   : $REPO"
echo "Tag    : $TAG"
echo

# Collect artifacts
DEB="installers/fuelle_${VERSION}_amd64.deb"
APK="installers/fuelle_${VERSION}.apk"
EXE="installers/fuelle_${VERSION}_setup.exe"
ASSETS=""
[ -f "$DEB" ] && ASSETS="$ASSETS $DEB" && echo "[+] $DEB"
[ -f "$APK" ] && ASSETS="$ASSETS $APK" && echo "[+] $APK"
[ -f "$EXE" ] && ASSETS="$ASSETS $EXE" && echo "[+] $EXE"

if [ -z "$ASSETS" ]; then
  echo "[WARN] No installer artifacts found in installers/"
  echo "  Build first: Windows (build_all.bat), Linux/Android (build_all.sh), Mac (build_all_mac.sh)"
fi

RELEASE_NOTES="## Fuelle $TAG — PrivacyChase

Privacy-first meal planner & nutrition tracker.

### What's new in $TAG
- Initial alpha release
- Meal logging: Breakfast, Lunch, Dinner, Snacks
- USDA FoodData Central food search
- Daily calorie, carb, protein, fat tracking
- Week view + history
- Custom nutrition goals
- Export/Import backup code (FUELLE1: format)
- Dark & Light mode
- Works on Windows, macOS, Linux, Android, iOS

### Install
- **Windows**: Run \`fuelle_${VERSION}_setup.exe\`
- **Android**: Install \`fuelle_${VERSION}.apk\` (enable unknown sources)
- **Linux**: \`sudo dpkg -i fuelle_${VERSION}_amd64.deb\`

### Privacy
No accounts. No servers. No tracking. No ads.

---
by [PrivacyChase](https://github.com/privacychase)"

echo
echo "Creating GitHub release $TAG..."
GH_CMD="gh release create \"$TAG\" --title \"Fuelle $TAG\" --notes \"$RELEASE_NOTES\" --repo \"$REPO\" --prerelease"
[ -n "$ASSETS" ] && GH_CMD="$GH_CMD $ASSETS"
eval $GH_CMD
echo "[OK] Release created: https://github.com/$REPO/releases/tag/$TAG"

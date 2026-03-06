#!/usr/bin/env bash
# fuelle build script — macOS and Linux
# Usage: bash build.sh [mac|linux|all]

PLATFORM="${1:-detect}"
RED='\033[0;31m'; GREEN='\033[0;32m'; BOLD='\033[1m'; NC='\033[0m'

# Keep terminal open if double-clicked from file manager (Linux)
LAUNCHED_FROM_FILEMANAGER=false
if [ -z "$TERM" ] || [ "$TERM" = "dumb" ]; then
    LAUNCHED_FROM_FILEMANAGER=true
fi

pause_if_needed() {
    if [ "$LAUNCHED_FROM_FILEMANAGER" = true ]; then
        echo ""
        read -p "Press Enter to close..." dummy
    fi
}

echo ""
echo -e "${BOLD} fuelle — Build Script${NC}"
echo " ========================"
echo ""

# ── Detect platform ───────────────────────────────────────────────────────────
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "mac" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}
[ "$PLATFORM" = "detect" ] && PLATFORM=$(detect_os)
echo -e " Platform: ${GREEN}$PLATFORM${NC}"
echo ""

# ── Check Node.js — just tell them to install it, no auto-install ─────────────
echo "[1/3] Checking for Node.js..."

if ! command -v node &>/dev/null; then
    echo ""
    echo -e " ${RED}[ERROR] Node.js is not installed.${NC}"
    echo ""
    if [ "$PLATFORM" = "mac" ]; then
        echo " Install it from: https://nodejs.org/en/download"
        echo " Choose the macOS installer (.pkg) — do NOT use Homebrew."
        echo " After installing, open a new Terminal and run this script again."
    else
        echo " Install it by running these two commands:"
        echo ""
        echo "   curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -"
        echo "   sudo apt-get install -y nodejs"
        echo ""
        echo " Then run this script again."
    fi
    echo ""
    pause_if_needed
    exit 1
fi

NODE_VER=$(node --version)
NPM_VER=$(npm --version)
echo -e " [OK] Node.js ${GREEN}$NODE_VER${NC} | npm ${GREEN}v$NPM_VER${NC}"
echo ""

# ── Install dependencies ──────────────────────────────────────────────────────
echo "[2/3] Installing dependencies..."
echo "      (First run downloads ~200MB — this may take a few minutes)"
echo ""

npm install
if [ $? -ne 0 ]; then
    echo -e "${RED}[ERROR] npm install failed. Check your internet connection.${NC}"
    pause_if_needed
    exit 1
fi
echo ""
echo -e " [OK] Dependencies ready."
echo ""

# ── Build ─────────────────────────────────────────────────────────────────────
echo "[3/3] Building..."
echo ""

case "$PLATFORM" in
    mac)
        npm run build:mac
        if [ $? -ne 0 ]; then
            echo -e "${RED}[ERROR] Build failed.${NC}"
            pause_if_needed; exit 1
        fi
        echo ""
        echo " Done! App is at: dist-electron/fuelle-0.6.0.dmg"
        open dist-electron 2>/dev/null || true
        ;;
    linux)
        # Install Linux build deps if on apt-based system
        if command -v apt-get &>/dev/null; then
            echo " Installing Linux build dependencies..."
            sudo apt-get install -y --no-install-recommends \
                libgtk-3-dev libnotify-dev libnss3 libxss1 \
                libxtst6 xdg-utils libatspi2.0-0 rpm fakeroot 2>/dev/null || true
            echo ""
        fi
        npm run build:linux
        if [ $? -ne 0 ]; then
            echo -e "${RED}[ERROR] Build failed.${NC}"
            pause_if_needed; exit 1
        fi
        echo ""
        echo " Done! Packages are in: dist-electron/"
        echo "   .deb  — install with: sudo dpkg -i dist-electron/*.deb"
        echo "   .AppImage — run with: chmod +x dist-electron/*.AppImage && ./dist-electron/*.AppImage"
        xdg-open dist-electron 2>/dev/null || true
        ;;
    all)
        npm run build:all
        if [ $? -ne 0 ]; then
            echo -e "${RED}[ERROR] Build failed.${NC}"
            pause_if_needed; exit 1
        fi
        echo ""
        echo " Done! Output in: dist-electron/"
        ;;
    *)
        echo -e "${RED}Usage: bash build.sh [mac|linux|all]${NC}"
        pause_if_needed; exit 1
        ;;
esac

echo ""
pause_if_needed

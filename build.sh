#!/usr/bin/env bash
# fuelle — auto-build script for macOS and Linux
# Usage: bash build.sh [win|mac|linux|all]
#        (defaults to current OS)

set -e
PLATFORM="${1:-detect}"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'; BOLD='\033[1m'

echo ""
echo -e "${BOLD} fuelle v0.5.0 — Build Script${NC}"
echo " =============================="
echo ""

# ── Step 1: Detect OS ─────────────────────────────────────────────────────────
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

# ── Step 2: Ensure Node.js is installed ───────────────────────────────────────
echo "[1/4] Checking for Node.js..."

install_node_mac() {
  echo "      Node.js not found. Installing via Homebrew..."
  if ! command -v brew &>/dev/null; then
    echo "      Homebrew not found — installing Homebrew first..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || true)"
    eval "$(/usr/local/bin/brew shellenv 2>/dev/null || true)"
  fi
  brew install node
}

install_node_linux() {
  echo "      Node.js not found. Installing via NodeSource..."
  if command -v apt-get &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
  elif command -v dnf &>/dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo dnf install -y nodejs
  elif command -v yum &>/dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
    sudo yum install -y nodejs
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm nodejs npm
  else
    echo -e "${RED}      [ERROR] Cannot auto-install Node.js on this distro.${NC}"
    echo "      Please install Node.js 20+ manually: https://nodejs.org"
    exit 1
  fi
}

if ! command -v node &>/dev/null; then
  case "$PLATFORM" in
    mac)   install_node_mac ;;
    linux) install_node_linux ;;
    *)
      echo -e "${RED}[ERROR] Node.js not found. Install from https://nodejs.org${NC}"
      exit 1
      ;;
  esac
fi

NODE_VER=$(node --version)
NPM_VER=$(npm --version)
echo -e " [OK] Node.js ${GREEN}$NODE_VER${NC} | npm ${GREEN}v$NPM_VER${NC}"
echo ""

# ── Step 3: Install npm dependencies ─────────────────────────────────────────
echo "[2/4] Installing dependencies (electron + electron-builder)..."
echo "      First run downloads ~200MB. Subsequent runs are fast."
echo ""
npm install
echo ""
echo -e " [OK] Dependencies ready."
echo ""

# ── Step 4: Build ─────────────────────────────────────────────────────────────
echo "[3/4] Building..."
echo ""

case "$PLATFORM" in
  win)
    echo "      Building Windows .exe..."
    npm run build:win
    OUTPUT="dist-electron/fuelle Setup 0.5.0.exe"
    ;;
  mac)
    echo "      Building macOS .dmg..."
    npm run build:mac
    OUTPUT="dist-electron/fuelle-0.5.0.dmg"
    ;;
  linux)
    # Install Linux build deps if needed
    if command -v apt-get &>/dev/null; then
      sudo apt-get install -y --no-install-recommends \
        libgtk-3-dev libnotify-dev libnss3 libxss1 libxtst6 \
        xdg-utils libatspi2.0-0 rpm 2>/dev/null || true
    fi
    echo "      Building Linux .deb + AppImage..."
    npm run build:linux
    OUTPUT="dist-electron/"
    ;;
  all)
    echo "      Building all desktop platforms..."
    npm run build:all
    OUTPUT="dist-electron/"
    ;;
  *)
    echo -e "${RED}Usage: bash build.sh [win|mac|linux|all]${NC}"
    exit 1
    ;;
esac

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "[4/4] Build complete!"
echo ""
echo -e " ${GREEN}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e " ${GREEN}│${NC}  Output: ${BOLD}$OUTPUT${NC}"
echo -e " ${GREEN}│${NC}  Install it on your device — no browser, no Flutter.    "
echo -e " ${GREEN}└──────────────────────────────────────────────────────────┘${NC}"
echo ""

# Open output folder
case "$PLATFORM" in
  mac)   open dist-electron 2>/dev/null || true ;;
  linux) xdg-open dist-electron 2>/dev/null || true ;;
esac

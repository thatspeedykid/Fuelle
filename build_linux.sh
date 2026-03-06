#!/usr/bin/env bash
# fuelle Linux build — double-click this in your file manager
# Right-click → Properties → Permissions → Allow executing as program
# Then double-click to run

# Force open in a terminal window so output is visible
if [ -z "$TERM" ] || [ "$TERM" = "dumb" ]; then
    # Try common terminal emulators
    if command -v gnome-terminal &>/dev/null; then
        gnome-terminal -- bash "$(realpath "$0")" --already-in-terminal
        exit 0
    elif command -v xterm &>/dev/null; then
        xterm -e bash "$(realpath "$0")" --already-in-terminal
        exit 0
    elif command -v konsole &>/dev/null; then
        konsole -e bash "$(realpath "$0")" --already-in-terminal
        exit 0
    elif command -v xfce4-terminal &>/dev/null; then
        xfce4-terminal -e "bash '$(realpath "$0")' --already-in-terminal"
        exit 0
    fi
fi

bash build.sh linux

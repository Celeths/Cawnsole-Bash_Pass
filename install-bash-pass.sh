#!/bin/bash
# ============================================================================
# install-bash-pass.sh — installs Bash Pass system-wide
#
# The main app (`pass`) resolves its help file relative to its own location
# (`source "$(dirname "$0")/bash-pass-help"`), so both files are always
# installed side by side:
#
#   pass             ->  <DIR>/bashpass         (the main app)
#   bash-pass-help   ->  <DIR>/bash-pass-help   (required by `bashpass -help`)
#
# Usage:
#   sudo ./install-bash-pass.sh               install to /usr/local/bin
#   sudo ./install-bash-pass.sh /custom/dir   install elsewhere (must be on PATH)
#   sudo ./install-bash-pass.sh -uninstall    remove the installed files
#   sudo ./install-bash-pass.sh /custom/dir -uninstall   remove from /custom/dir
# ============================================================================

set -euo pipefail

# Directory this script lives in (where `pass` & `bash-pass-help` are)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_PASS="$SCRIPT_DIR/pass"
SRC_HELP="$SCRIPT_DIR/bash-pass-help"

INSTALL_DIR="/usr/local/bin"
UNINSTALL=0

case "${1:-}" in
    "" )
        ;;
    -uninstall|--uninstall|-remove)
        UNINSTALL=1
        ;;
    -h|--help)
        echo "Usage: sudo $0 [INSTALL_DIR]"
        echo "       sudo $0 [INSTALL_DIR] -uninstall"
        echo "       sudo $0 -uninstall"
        exit 0
        ;;
    * )
        INSTALL_DIR="$1"
        # A second argument may request uninstalling from that custom dir:
        # `sudo ./install-bash-pass.sh /custom/dir -uninstall`
        case "${2:-}" in
            -uninstall|--uninstall|-remove)
                UNINSTALL=1
                ;;
        esac
        ;;
esac

# --- root check ------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    echo "install-bash-pass.sh requires root access (run with sudo)." >&2
    exit 1
fi

# --- uninstall -------------------------------------------------------------
if [ "$UNINSTALL" -eq 1 ]; then
    for file in "$INSTALL_DIR/bashpass" "$INSTALL_DIR/bash-pass-help"; do
        if [ -e "$file" ]; then
            rm -f "$file"
            echo "Removed: $file"
        else
            echo "Not installed: $file"
        fi
    done
    echo "Bash Pass uninstalled."
    exit 0
fi

# --- source file checks ----------------------------------------------------
for file in "$SRC_PASS" "$SRC_HELP"; do
    if [ ! -f "$file" ]; then
        echo "Error: required file not found: $file" >&2
        echo "Run this script from the Bash Pass repository directory." >&2
        exit 1
    fi
done

# --- install ---------------------------------------------------------------
mkdir -p "$INSTALL_DIR"

install -m 0755 "$SRC_PASS" "$INSTALL_DIR/bashpass"
install -m 0755 "$SRC_HELP" "$INSTALL_DIR/bash-pass-help"

echo "Installed Bash Pass to $INSTALL_DIR:"
echo "  $INSTALL_DIR/bashpass"
echo "  $INSTALL_DIR/bash-pass-help"

# --- verify ----------------------------------------------------------------
if "$INSTALL_DIR/bashpass" -version >/dev/null 2>&1; then
    echo "Installation verified: $("$INSTALL_DIR/bashpass" -version 2>/dev/null)"
else
    echo "Warning: the installed binary did not respond to 'bashpass -version'." >&2
fi

# --- PATH notice -----------------------------------------------------------
case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *) echo "Notice: $INSTALL_DIR is not on PATH — run Bash Pass with the full path or add it to PATH." >&2 ;;
esac

echo
echo "Bash Pass is ready to use. Run it with:  sudo bashpass"

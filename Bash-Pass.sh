#!/bin/bash

# Validate dependencies
if ! command -v dialog &> /dev/null; then
    echo "Error: Required dependency 'dialog' is not installed."
    exit 1
fi

# Enforce elevated privileges for memory extraction
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (with sudo)."
    exit 1
fi

# Locate active KDE Plasma sessions
PIDS=$(pgrep -x plasmashell)

if [ -z "$PIDS" ]; then
    echo "Error: No active sessions detected."
    exit 1
fi

# Construct TUI menu array based on detected processes
OPTS=()
for pid in $PIDS; do
    USER=$(ps -o user= -p "$pid" | tr -d ' ')
    OPTS+=("$USER" "PID: $pid")
done

# Initialize the TUI dialog
TARGET_USER=$(dialog --clear --title "Bash Pass Active" \
    --menu "Select the target user session:" 10 50 4 \
    "${OPTS[@]}" 2>&1 >/dev/tty)

clear

# Handle user cancellation
if [ -z "$TARGET_USER" ]; then
    echo "Operation aborted by user."
    exit 0
fi

# Isolate the specific PID for the chosen user
TARGET_PID=$(pgrep -u "$TARGET_USER" -x plasmashell | head -n 1)

# Extract environment variables from the active session
export WAYLAND_DISPLAY=$(grep -z "^WAYLAND_DISPLAY=" /proc/"$TARGET_PID"/environ | cut -d= -f2 | tr -d '\0')
export DISPLAY=$(grep -z "^DISPLAY=" /proc/"$TARGET_PID"/environ | cut -d= -f2 | tr -d '\0')
export XDG_RUNTIME_DIR=$(grep -z "^XDG_RUNTIME_DIR=" /proc/"$TARGET_PID"/environ | cut -d= -f2 | tr -d '\0')
export DBUS_SESSION_BUS_ADDRESS=$(grep -z "^DBUS_SESSION_BUS_ADDRESS=" /proc/"$TARGET_PID"/environ | cut -d= -f2- | tr -d '\0')

# Confirm extraction and format output
echo "Environment variables successfully extracted:"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "DISPLAY=$DISPLAY"
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
echo "DBUS=$DBUS_SESSION_BUS_ADDRESS"
echo ""
echo "Initialized pass for user: $TARGET_USER"

# Downgrade privileges and spawn the shell with preserved environment variables
sudo --preserve-env=WAYLAND_DISPLAY,DISPLAY,XDG_RUNTIME_DIR,DBUS_SESSION_BUS_ADDRESS -u "$TARGET_USER" /bin/bash
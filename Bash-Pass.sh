#!/bin/bash

# Validate dependencies and set TUI binary
if command -v dialog &> /dev/null; then
    TUI_CMD="dialog"
elif command -v whiptail &> /dev/null; then
    TUI_CMD="whiptail"
else
    echo "Error: Neither 'dialog' nor 'whiptail' is installed. Fix your shit."
    exit 1
fi

# Validate permissions
if [ "$EUID" -ne 0 ]; then
    echo "Error: Root privileges required run Bash Pass (run with sudo)."
    exit 1
fi

# UID Check
OPTS=()
ALPHABET=({A..Z} {A..Z}{A..Z})
INDEX=0

while IFS=: read -r username _ uid _ _ _ _; do
    if [ "$uid" -ge 1000 ] && [ "$uid" -ne 65534 ]; then
        # Check if active and harvest the oldest PID to anchor the display
        if APEX_PID=$(pgrep -o -u "$username" 2>/dev/null); then
            # Classify the session type
            if pgrep -u "$username" | xargs -I{} grep -l -z "^WAYLAND_DISPLAY=" /proc/{}/environ 2>/dev/null | grep -q .; then
                SESS_TYPE="Wayland"
            elif pgrep -u "$username" | xargs -I{} grep -l -z "^DISPLAY=" /proc/{}/environ 2>/dev/null | grep -q .; then
                SESS_TYPE="X11"
            else
                SESS_TYPE="Terminal"
            fi
            
            # Format the menu strings
            TAG="${ALPHABET[$INDEX]} - $username"
            DESC="PID: $APEX_PID | $SESS_TYPE"
            OPTS+=("$TAG" "$DESC")
            ((INDEX++))
        fi
    fi
done < /etc/passwd

if [ ${#OPTS[@]} -eq 0 ]; then
    echo "Error: No active sessions detected."
    exit 1
fi

# Main screen
MENU_SELECTION=$($TUI_CMD --title "Bash Pass" \
    --menu "Select the active session to enter:" 12 50 4 \
    "${OPTS[@]}" 3>&1 1>&2 2>&3)

clear

# User cancellation
if [ -z "$MENU_SELECTION" ]; then
    echo "Exited."
    exit 0
fi

# Extract the bare username
TARGET_USER="${MENU_SELECTION#* - }"

# Telemetry Targetting
extract_telemetry() {
    local user="$1"
    local target_var="$2"
    
    # Sift for target
    for pid in $(pgrep -u "$user"); do
        local val=$(grep -z "^${target_var}=" /proc/"$pid"/environ 2>/dev/null | cut -d= -f2- | tr -d '\0')
        if [ -n "$val" ]; then
            echo "$val"
            return 0
        fi
    done
}

# Environment variable telemetry
WAYLAND_DISPLAY=$(extract_telemetry "$TARGET_USER" "WAYLAND_DISPLAY")
DISPLAY=$(extract_telemetry "$TARGET_USER" "DISPLAY")
XDG_RUNTIME_DIR=$(extract_telemetry "$TARGET_USER" "XDG_RUNTIME_DIR")
DBUS_SESSION_BUS_ADDRESS=$(extract_telemetry "$TARGET_USER" "DBUS_SESSION_BUS_ADDRESS")

# Format and confirm output
echo "Your Bash Pass:"
echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-[Null]}"
echo "DISPLAY=${DISPLAY:-[Null]}"
echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-[Null]}"
echo "DBUS=${DBUS_SESSION_BUS_ADDRESS:-[Null]}"
echo ""
echo "Presenting pass to system..."

# Export the variables
export WAYLAND_DISPLAY DISPLAY XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS

# Downgrade privileges and start the shell with injected payload
sudo --preserve-env=WAYLAND_DISPLAY,DISPLAY,XDG_RUNTIME_DIR,DBUS_SESSION_BUS_ADDRESS -u "$TARGET_USER" /bin/bash -c "echo ''; echo 'Bash Pass Accepted. Welcome $TARGET_USER.'; echo ''; exec /bin/bash"

echo ""
echo "Bash Pass Session Ended."
echo ""
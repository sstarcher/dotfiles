#!/usr/bin/env bash
# Scroll threshold tracker for tmux
# Only enters copy mode after multiple scroll-up events in quick succession

THRESHOLD=3  # Number of scrolls needed to enter copy mode
TIMEOUT=1    # Seconds before counter resets

COUNTER_FILE="/tmp/tmux-scroll-counter-${TMUX_PANE}"

# Read current count
if [[ -f "$COUNTER_FILE" ]]; then
    COUNT=$(cat "$COUNTER_FILE" 2>/dev/null || echo "0")
    # Get file modification time (Linux syntax)
    LAST_TIME=$(stat -c %Y "$COUNTER_FILE" 2>/dev/null || echo "0")
    CURRENT_TIME=$(date +%s)

    # Reset if timeout exceeded
    if (( CURRENT_TIME - LAST_TIME > TIMEOUT )); then
        COUNT=0
    fi
else
    COUNT=0
fi

# Increment counter
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER_FILE"

# If threshold reached, enter copy mode and reset
if (( COUNT >= THRESHOLD )); then
    rm -f "$COUNTER_FILE"
    tmux copy-mode -e
fi

# Always send the scroll event
tmux send-keys -M

# Exit successfully
exit 0

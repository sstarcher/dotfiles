#!/usr/bin/env bash
# Reset tmux layout to simple 2-pane side-by-side when agents shut down
# Left: Claude lead pane | Right: Terminal pane

set -u

# Parse --quiet flag (suppress display-message notifications)
QUIET=0
for arg in "$@"; do
    [ "$arg" = "--quiet" ] && QUIET=1
done

notify() {
    [ "$QUIET" -eq 0 ] && tmux display-message "$1"
}

# Count panes (always succeed even if command fails)
PANE_COUNT=$(tmux list-panes 2>/dev/null | wc -l) || exit 0

# Only reset if exactly 2 panes
if [ "$PANE_COUNT" -ne 2 ]; then
    exit 0
fi

# Find the panes tagged as @is_center (claude) and @is_terminal
CENTER_PANE=""
TERMINAL_PANE=""

while IFS= read -r pane; do
    if [ "$(tmux show-option -pqv -t "$pane" @is_center 2>/dev/null)" = "1" ]; then
        CENTER_PANE="$pane"
    elif [ "$(tmux show-option -pqv -t "$pane" @is_terminal 2>/dev/null)" = "1" ]; then
        TERMINAL_PANE="$pane"
    fi
done < <(tmux list-panes -F '#{pane_id}')

# If we have both tagged panes, arrange them side-by-side
if [ -n "$CENTER_PANE" ] && [ -n "$TERMINAL_PANE" ]; then
    # Break terminal pane to temporary window
    tmux break-pane -d -s "$TERMINAL_PANE" 2>/dev/null || {
        notify "Failed to break terminal pane"
        exit 0
    }

    # Join terminal pane to the right of center (50/50 split)
    tmux join-pane -h -t "$CENTER_PANE" -s "$TERMINAL_PANE" -l '50%' 2>/dev/null || {
        notify "Failed to join terminal pane"
        exit 0
    }

    # Focus on center/claude pane
    tmux select-pane -t "$CENTER_PANE" 2>/dev/null || true

    notify "Reset to 2-pane layout: Claude (left) | Terminal (right)"
else
    # Fallback: just use even-horizontal layout
    tmux select-layout even-horizontal 2>/dev/null || true
    notify "Reset to 2-pane layout"
fi

# Always exit successfully to prevent tmux error popups
exit 0

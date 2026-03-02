#!/bin/bash
# Claude hook: tmux team layout management
# Automatically reorganizes tmux panes when using Claude Code teams
#
# TeammateIdle: Triggers 3-column team layout (once per session)
# SubagentStop: Resets to 2-pane layout when agent count drops to 2
# SessionEnd: Clears the auto-applied flag

set -e

EVENT_TYPE="$1"
LOG_FILE="$HOME/.claude/layout.log"

# Function to log and echo to both stdout and log file
log_and_echo() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Validate event type
if [ -z "$EVENT_TYPE" ]; then
    log_and_echo "ERROR: No event type provided. Usage: tmux-layout.sh <event_type>"
    exit 1
fi

# Ensure we have TMUX_PANE
if [ -z "${TMUX_PANE}" ]; then
    if [ -n "${TMUX}" ]; then
        TMUX_PANE=$(tmux display-message -p '#{pane_id}')
    else
        log_and_echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $EVENT_TYPE not in tmux"
        exit 1
    fi
fi

# Get window index
WINDOW=$(tmux display-message -pt "${TMUX_PANE}" '#{window_index}' 2>&1)
if [ $? -ne 0 ]; then
    log_and_echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $EVENT_TYPE failed to get window for ${TMUX_PANE}"
    exit 1
fi

# Handle different event types
case "$EVENT_TYPE" in
    TeammateIdle)
        # Trigger team layout reorganization when teammates go idle (after spawning)
        # Only do this once per team session using a window flag
        LAYOUT_APPLIED=$(tmux show-options -w -t ":$WINDOW" @team_layout_auto_applied 2>/dev/null | awk '{print $2}')

        if [ "$LAYOUT_APPLIED" != "1" ]; then
            # Count panes - only reorganize if we have multiple agents
            PANE_COUNT=$(tmux list-panes -t ":$WINDOW" | wc -l)

            if [ "$PANE_COUNT" -ge 3 ]; then
                # Small delay to ensure all agents have spawned
                (sleep 2 && { tmux run-shell -t ":$WINDOW" "$HOME/.tmux/team-layout.sh --quiet" 2>/dev/null || true; }) &
                tmux set-option -w -t ":$WINDOW" @team_layout_auto_applied "1"
                ACTION="(triggering team layout)"
            fi
        fi
        ;;

    SubagentStop)
        # Check if all agents are gone - if only 2 panes left, reset to simple layout
        PANE_COUNT=$(tmux list-panes -t ":$WINDOW" | wc -l)
        if [ "$PANE_COUNT" -eq 2 ]; then
            # Small delay to ensure subagent pane is fully cleaned up
            (sleep 1 && { tmux run-shell -t ":$WINDOW" "$HOME/.tmux/reset-layout.sh --quiet" 2>/dev/null || true; }) &
            tmux set-option -wu -t ":$WINDOW" @team_layout_auto_applied
            ACTION="(resetting to 2-pane layout)"
        fi
        ;;

    SessionEnd)
        # Clear the auto-applied flag so next team session can trigger layout
        tmux set-option -wu -t ":$WINDOW" @team_layout_auto_applied
        ACTION="(cleared layout flag)"
        ;;

    SessionStart|PostToolUse|PostToolUseFailure|SubagentStart|TaskCompleted|PreCompact|Stop|UserPromptSubmit|PermissionRequest|PreToolUse|IdlePrompt)
        # These events don't need layout handling
        ACTION=""
        ;;

    *)
        log_and_echo "[$(date '+%Y-%m-%d %H:%M:%S')] win:$WINDOW ERROR: Unknown hook $EVENT_TYPE"
        exit 1
        ;;
esac

if [ -n "$ACTION" ]; then
    log_and_echo "[$(date '+%Y-%m-%d %H:%M:%S')] win:$WINDOW $EVENT_TYPE -> $ACTION"
fi

#!/bin/bash
# Claude hooks script for managing tmux window status colors
# Usage: tmux-status.sh <event_type>
# Event types: Stop, UserPromptSubmit, SessionEnd, PermissionRequest, IdlePrompt, TeammateIdle

set -e

# ============================================================================
# Configuration - Colors and Styles
# ============================================================================
# Override these by setting environment variables (e.g., CLAUDE_COLOR_PROCESSING=blue)
# Available colors: black, red, green, yellow, blue, magenta, cyan, white, default
# Can also use: brightred, brightgreen, brightblue, etc.
# Can add modifiers: bold, dim, underscore, blink, reverse, hidden

# Color for processing user input (UserPromptSubmit)
COLOR_PROCESSING="${CLAUDE_COLOR_PROCESSING:-fg=white,bg=colour21}"
COLOR_PROCESSING_CURRENT="${CLAUDE_COLOR_PROCESSING_CURRENT:-fg=white,bg=colour21,bold}"

# Color for finished/idle state (Stop without done flag)
COLOR_FINISHED="${CLAUDE_COLOR_FINISHED:-fg=white,bg=colour22}"
COLOR_FINISHED_CURRENT="${CLAUDE_COLOR_FINISHED_CURRENT:-fg=white,bg=colour22,bold}"

# Color for waiting states (PermissionRequest, TeammateIdle)
COLOR_WAITING="${CLAUDE_COLOR_WAITING:-fg=white,bg=colour88}"
COLOR_WAITING_CURRENT="${CLAUDE_COLOR_WAITING_CURRENT:-fg=white,bg=colour88,bold}"

# Default/reset color (Stop with done flag, SessionEnd)
COLOR_DEFAULT="${CLAUDE_COLOR_DEFAULT:-default}"
COLOR_DEFAULT_CURRENT="${CLAUDE_COLOR_DEFAULT_CURRENT:-default}"

# ============================================================================

EVENT_TYPE="$1"
LOG_FILE="$HOME/.claude/hook.log"

# Function to log and echo to both stdout and log file
log_and_echo() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Validate event type
if [ -z "$EVENT_TYPE" ]; then
    log_and_echo "ERROR: No event type provided. Usage: tmux-status.sh <event_type>"
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
    Stop)
        # Check if CLAUDE_DONE is set for this window (window-specific option)
        CLAUDE_DONE=$(tmux show-options -w -t ":$WINDOW" @claude_done 2>/dev/null | awk '{print $2}')
        if [ "$CLAUDE_DONE" = "1" ]; then
            tmux set-option -w -t ":$WINDOW" window-status-style "$COLOR_DEFAULT"
            tmux set-option -w -t ":$WINDOW" window-status-current-style "$COLOR_DEFAULT_CURRENT"
            tmux set-option -wu -t ":$WINDOW" @claude_done
            ACTION="$COLOR_DEFAULT (done)"
        else
            tmux set-option -w -t ":$WINDOW" window-status-style "$COLOR_FINISHED"
            tmux set-option -w -t ":$WINDOW" window-status-current-style "$COLOR_FINISHED_CURRENT"
            ACTION="$COLOR_FINISHED (finished)"
        fi
        ;;

    UserPromptSubmit)
        tmux set-option -w -t ":$WINDOW" window-status-style "$COLOR_PROCESSING"
        tmux set-option -w -t ":$WINDOW" window-status-current-style "$COLOR_PROCESSING_CURRENT"
        ACTION="$COLOR_PROCESSING (processing)"
        ;;

    SessionEnd)
        tmux set-option -w -t ":$WINDOW" window-status-style "$COLOR_DEFAULT"
        tmux set-option -w -t ":$WINDOW" window-status-current-style "$COLOR_DEFAULT_CURRENT"
        ACTION="$COLOR_DEFAULT (session end)"
        ;;

    PermissionRequest)
        tmux set-option -w -t ":$WINDOW" window-status-style "$COLOR_WAITING"
        tmux set-option -w -t ":$WINDOW" window-status-current-style "$COLOR_WAITING_CURRENT"
        ACTION="$COLOR_WAITING (waiting)"
        ;;

    TeammateIdle)
        tmux set-option -w -t ":$WINDOW" window-status-style "$COLOR_WAITING"
        tmux set-option -w -t ":$WINDOW" window-status-current-style "$COLOR_WAITING_CURRENT"
        ACTION="$COLOR_WAITING (teammate idle)"
        ;;

    PreToolUse)
        tmux set-option -w -t ":$WINDOW" window-status-style "$COLOR_PROCESSING"
        tmux set-option -w -t ":$WINDOW" window-status-current-style "$COLOR_PROCESSING_CURRENT"
        ACTION="$COLOR_PROCESSING (working)"
        ;;

    SessionStart|IdlePrompt|PostToolUse|PostToolUseFailure|SubagentStart|SubagentStop|TaskCompleted|PreCompact)
        ACTION=""
        ;;

    *)
        log_and_echo "[$(date '+%Y-%m-%d %H:%M:%S')] win:$WINDOW ERROR: Unknown hook $EVENT_TYPE"
        exit 1
        ;;
esac

if [ -n "$ACTION" ]; then
    log_and_echo "[$(date '+%Y-%m-%d %H:%M:%S')] win:$WINDOW $EVENT_TYPE -> $ACTION"
else
    log_and_echo "[$(date '+%Y-%m-%d %H:%M:%S')] win:$WINDOW $EVENT_TYPE"
fi

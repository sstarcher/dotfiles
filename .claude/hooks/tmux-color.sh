#!/bin/bash
# Claude hook: tmux window color management
# Provides visual feedback for Claude state via tmux window status colors
#
# Blocking state: PermissionRequest increments @claude_blocking_count (red color, sticky)
#   Decremented by: IdlePrompt (one permission handled)
#                   SubagentStop (one agent stopped)
#   Reset to 0 by:  UserPromptSubmit (user responded)
#                   SessionEnd (session ended)
#
# Stop behavior: Delayed green transition (3s) to avoid flickering during active work
#   Stop sets @claude_stop_time and schedules delayed green transition
#   PreToolUse/UserPromptSubmit clear the timer (cancels transition, stays blue)

set -e

# ============================================================================
# Configuration - Colors and Styles
# ============================================================================
# Override these by setting environment variables (e.g., CLAUDE_COLOR_PROCESSING=blue)
# Available colors: black, red, green, yellow, blue, magenta, cyan, white, default
# Can also use: brightred, brightgreen, brightblue, etc.
# Can add modifiers: bold, dim, underscore, blink, reverse, hidden

# Color for processing user input (UserPromptSubmit)
# Note: Active window uses brackets in format, not different colors
COLOR_PROCESSING="${CLAUDE_COLOR_PROCESSING:-fg=white,bg=colour21}"
COLOR_PROCESSING_CURRENT="${CLAUDE_COLOR_PROCESSING_CURRENT:-fg=white,bg=colour21}"

# Color for finished/idle state (Stop without done flag)
COLOR_FINISHED="${CLAUDE_COLOR_FINISHED:-fg=white,bg=colour22}"
COLOR_FINISHED_CURRENT="${CLAUDE_COLOR_FINISHED_CURRENT:-fg=white,bg=colour22}"

# Color for waiting states (PermissionRequest only)
COLOR_WAITING="${CLAUDE_COLOR_WAITING:-fg=white,bg=colour88}"
COLOR_WAITING_CURRENT="${CLAUDE_COLOR_WAITING_CURRENT:-fg=white,bg=colour88}"

# Default/reset color (Stop with done flag, SessionEnd)
COLOR_DEFAULT="${CLAUDE_COLOR_DEFAULT:-default}"
COLOR_DEFAULT_CURRENT="${CLAUDE_COLOR_DEFAULT_CURRENT:-default}"

# ============================================================================

EVENT_TYPE="$1"
LOG_FILE="$HOME/.claude/color.log"

# Log all parameters and relevant environment for debugging
# Uncomment to debug: echo "DEBUG Args: $@ | Env: $(env | grep -E 'CLAUDE_COLOR|TMUX' | tr '\n' ' ')" >> "$LOG_FILE"

# Function to log and echo to both stdout and log file
log_and_echo() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Validate event type
if [ -z "$EVENT_TYPE" ]; then
    log_and_echo "ERROR: No event type provided. Usage: tmux-color.sh <event_type>"
    exit 1
fi

# Ensure we have TMUX_PANE
if [ -z "${TMUX_PANE}" ]; then
    if [ -n "${TMUX}" ]; then
        TMUX_PANE=$(tmux display-message -p '#{pane_id}')
    else
        # Not in tmux, silently return
        exit 0
    fi
fi

# Get window index
WINDOW=$(tmux display-message -pt "${TMUX_PANE}" '#{window_index}' 2>&1)
if [ $? -ne 0 ]; then
    log_and_echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $EVENT_TYPE failed to get window for ${TMUX_PANE}"
    exit 1
fi

# Read blocking counter (0 = not blocked, >0 = number of pending permission requests)
BLOCKING_COUNT=$(tmux show-options -w -t ":$WINDOW" @claude_blocking_count 2>/dev/null | awk '{print $2}')
BLOCKING_COUNT=${BLOCKING_COUNT:-0}

# Helper function to set window status
set_status() {
    local style="$1"
    local style_current="$2"
    local action="$3"
    tmux set-option -w -t ":$WINDOW" window-status-style "$style"
    tmux set-option -w -t ":$WINDOW" window-status-current-style "$style_current"
    ACTION="$action"
}

# Increment blocking counter (new permission request)
increment_blocking() {
    BLOCKING_COUNT=$((BLOCKING_COUNT + 1))
    tmux set-option -w -t ":$WINDOW" @claude_blocking_count "$BLOCKING_COUNT"
}

# Decrement blocking counter (one permission resolved); clears option at 0
decrement_blocking() {
    if [ "$BLOCKING_COUNT" -gt 0 ]; then
        BLOCKING_COUNT=$((BLOCKING_COUNT - 1))
    fi
    if [ "$BLOCKING_COUNT" -eq 0 ]; then
        tmux set-option -wu -t ":$WINDOW" @claude_blocking_count
    else
        tmux set-option -w -t ":$WINDOW" @claude_blocking_count "$BLOCKING_COUNT"
    fi
}

# Reset blocking counter to 0 (full clear)
reset_blocking() {
    BLOCKING_COUNT=0
    tmux set-option -wu -t ":$WINDOW" @claude_blocking_count
}

# Handle different event types
case "$EVENT_TYPE" in
    Stop)
        # Don't override blocking state
        if [ "$BLOCKING_COUNT" -gt 0 ]; then
            ACTION="(blocked x${BLOCKING_COUNT}, not clearing)"
        else
            # Check if CLAUDE_DONE is set for this window (window-specific option)
            CLAUDE_DONE=$(tmux show-options -w -t ":$WINDOW" @claude_done 2>/dev/null | awk '{print $2}')
            if [ "$CLAUDE_DONE" = "1" ]; then
                set_status "$COLOR_DEFAULT" "$COLOR_DEFAULT_CURRENT" "default (done)"
                tmux set-option -wu -t ":$WINDOW" @claude_done
            else
                # Delayed green transition: only turn green if still stopped after 3 seconds
                # This prevents flickering during active work (Stop -> PreToolUse -> Stop)
                STOP_TIME=$(date +%s)
                tmux set-option -w -t ":$WINDOW" @claude_stop_time "$STOP_TIME"

                # Schedule delayed transition in background
                (
                    sleep 3
                    # Check if still stopped (timestamp unchanged)
                    CURRENT_STOP_TIME=$(tmux show-options -w -t ":$WINDOW" @claude_stop_time 2>/dev/null | awk '{print $2}')
                    if [ "$CURRENT_STOP_TIME" = "$STOP_TIME" ]; then
                        # Still stopped after delay, turn green
                        tmux set-option -w -t ":$WINDOW" window-status-style "$COLOR_FINISHED"
                        tmux set-option -w -t ":$WINDOW" window-status-current-style "$COLOR_FINISHED_CURRENT"
                        tmux set-option -wu -t ":$WINDOW" @claude_stop_time
                        echo "[$(date '+%Y-%m-%d %H:%M:%S')] win:$WINDOW Stop (delayed) -> green (finished)" >> "$LOG_FILE"
                    fi
                ) &
                ACTION="(scheduled green in 3s)"
            fi
        fi
        ;;

    UserPromptSubmit)
        # User responded, reset all blocking, clear stop timer, and set to processing
        reset_blocking
        tmux set-option -wu -t ":$WINDOW" @claude_stop_time
        set_status "$COLOR_PROCESSING" "$COLOR_PROCESSING_CURRENT" "blue (processing)"
        ;;

    SessionEnd)
        # Session ending, always clear
        reset_blocking
        tmux set-option -wu -t ":$WINDOW" @claude_stop_time
        set_status "$COLOR_DEFAULT" "$COLOR_DEFAULT_CURRENT" "default (session end)"
        ;;

    SubagentStop)
        # Subagent stopped, decrement blocking counter
        if [ "$BLOCKING_COUNT" -gt 0 ]; then
            decrement_blocking
            if [ "$BLOCKING_COUNT" -eq 0 ]; then
                set_status "$COLOR_DEFAULT" "$COLOR_DEFAULT_CURRENT" "default (subagent stopped, unblocked)"
            else
                ACTION="(subagent stopped, still blocked x${BLOCKING_COUNT})"
            fi
        else
            ACTION=""
        fi
        ;;

    PermissionRequest)
        # Increment blocking counter and set waiting color
        increment_blocking
        set_status "$COLOR_WAITING" "$COLOR_WAITING_CURRENT" "red (waiting x${BLOCKING_COUNT})"
        ;;

    PreToolUse)
        # Clear any pending stop timer (work resuming, cancel green transition)
        tmux set-option -wu -t ":$WINDOW" @claude_stop_time

        # Don't override blocking state
        if [ "$BLOCKING_COUNT" -eq 0 ]; then
            set_status "$COLOR_PROCESSING" "$COLOR_PROCESSING_CURRENT" "blue (working)"
        else
            ACTION="(blocked x${BLOCKING_COUNT}, not changing)"
        fi
        ;;

    IdlePrompt)
        # Decrement blocking if set - IdlePrompt often fires after permission granted
        if [ "$BLOCKING_COUNT" -gt 0 ]; then
            decrement_blocking
            if [ "$BLOCKING_COUNT" -eq 0 ]; then
                ACTION="(permission granted, unblocked)"
            else
                ACTION="(permission granted, still blocked x${BLOCKING_COUNT})"
            fi
        else
            ACTION=""
        fi
        ;;

    SessionStart|PostToolUse|PostToolUseFailure|SubagentStart|TaskCompleted|PreCompact)
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

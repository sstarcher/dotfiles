#!/usr/bin/env bash
# Minimal team layout reorganization for Claude Code agents
# Extracts core functionality from AlexHarn/tmux-config
# Usage: tmux bind t run-shell '~/.tmux/team-layout.sh'

set -u

# Parse --quiet flag (suppress display-message notifications)
QUIET=0
for arg in "$@"; do
    [ "$arg" = "--quiet" ] && QUIET=1
done

notify() {
    [ "$QUIET" -eq 0 ] && tmux display-message "$1"
}

# =====================================================================
# Helpers
# =====================================================================

get_option() {
    tmux show-option -gqv "$1"
}

get_pane_option() {
    tmux show-option -pqv -t "${1:-}" "$2" 2>/dev/null
}

center_width() {
    local w
    w=$(get_option @center_width)
    echo "${w:-200}"  # Wide center column for comfortable editing
}

count_panes() {
    tmux list-panes -F '#{pane_id}' | wc -l
}

tag_center() {
    tmux set-option -p -t "$1" @is_center 1
}

tag_terminal() {
    tmux set-option -p -t "$1" @is_terminal 1
}

# Equalize heights of panes in the same column
equalize_column() {
    local -a panes=("$@")
    local count=${#panes[@]}
    if [ "$count" -le 1 ]; then return; fi

    local window_height
    window_height=$(tmux display-message -p '#{window_height}')
    local target=$(( window_height / count ))

    local i
    for i in $(seq 0 $((count - 2))); do
        tmux resize-pane -t "${panes[$i]}" -y "$target" 2>/dev/null || true
    done
}

# =====================================================================
# Auto-layout: Reorganize panes into 3-column structure
# =====================================================================

auto_layout() {
    # Classify all panes by tag
    local center=""
    local terminal=""
    local -a others=()

    while IFS= read -r pane; do
        if [ "$(get_pane_option "$pane" @is_center)" = "1" ]; then
            center="$pane"
        elif [ "$(get_pane_option "$pane" @is_terminal)" = "1" ]; then
            terminal="$pane"
        else
            others+=("$pane")
        fi
    done < <(tmux list-panes -F '#{pane_id}')

    # No tagged center pane → not a managed window, skip
    if [ -z "$center" ]; then return; fi

    local n=${#others[@]}

    # Need at least 2 untagged panes to justify 3-column layout
    if [ "$n" -lt 2 ]; then
        notify "Need at least 3 panes total (1 lead + 2+ agents)"
        return
    fi

    # Break all non-center panes to temporary windows
    for pane in "${others[@]}"; do
        tmux break-pane -d -s "$pane"
    done

    # Break terminal pane too if it exists
    if [ -n "$terminal" ]; then
        tmux break-pane -d -s "$terminal"
    fi

    # Calculate column widths
    local total_width cw sw
    total_width=$(tmux display-message -p '#{window_width}')
    cw=$(center_width)

    if [ "$total_width" -le "$cw" ]; then
        # Terminal too narrow; tile everything
        for pane in "${others[@]}"; do
            tmux join-pane -v -t "$center" -s "$pane"
        done
        if [ -n "$terminal" ]; then
            tmux join-pane -v -t "$center" -s "$terminal"
        fi
        tmux select-layout tiled
        tmux select-pane -t "$center"
        notify "Terminal too narrow for 3-column layout, using tiled"
        return
    fi

    sw=$(( (total_width - cw) / 2 ))

    # Distribute: left = floor(n/2), right = ceil(n/2)
    local left_count=$(( n / 2 ))
    local right_count=$(( n - left_count ))

    # --- Right column ---
    local right_anchor_idx=$left_count
    tmux join-pane -h -t "$center" -s "${others[$right_anchor_idx]}" -l "$sw"
    local i
    for i in $(seq $((right_anchor_idx + 1)) $((n - 1))); do
        tmux join-pane -v -t "${others[$right_anchor_idx]}" -s "${others[$i]}"
    done

    # --- Left column ---
    tmux join-pane -hb -t "$center" -s "${others[0]}" -l "$sw"
    for i in $(seq 1 $((left_count - 1))); do
        tmux join-pane -v -t "${others[0]}" -s "${others[$i]}"
    done

    # --- Terminal pane in center column above lead ---
    if [ -n "$terminal" ]; then
        # Place terminal above center pane, taking 25% of center column height
        tmux join-pane -vb -t "$center" -s "$terminal" -l '25%'
    fi

    # --- Equalize agent pane heights within each column ---
    equalize_column "${others[@]:0:$left_count}"
    equalize_column "${others[@]:$left_count:$right_count}"

    tmux select-pane -t "$center"

    if [ -n "$terminal" ]; then
        notify "Team layout: $left_count left | 1 term + 1 lead | $right_count right"
    else
        notify "Team layout: $left_count left | 1 center | $right_count right"
    fi
}

# =====================================================================
# Team: Tag current pane as center and reorganize
# =====================================================================

team() {
    local pane_count
    pane_count=$(count_panes) || {
        notify "Failed to count panes"
        return 0
    }

    if [ "$pane_count" -lt 3 ]; then
        notify "Need at least 3 panes (1 lead + 2+ agents)"
        return 0
    fi

    # Check if we have tagged panes already
    local has_center=""
    local has_terminal=""

    while IFS= read -r pane; do
        if [ "$(get_pane_option "$pane" @is_center)" = "1" ]; then
            has_center=1
        fi
        if [ "$(get_pane_option "$pane" @is_terminal)" = "1" ]; then
            has_terminal=1
        fi
    done < <(tmux list-panes -F '#{pane_id}')

    # If no center pane tagged, tag the current one
    if [ -z "$has_center" ]; then
        local current_pane
        current_pane="$(tmux display-message -p '#{pane_id}')"
        tag_center "$current_pane"
        notify "Tagged current pane as center/lead"
    fi

    # If no terminal pane tagged, create one
    if [ -z "$has_terminal" ]; then
        local center_pane
        # Find the center pane
        while IFS= read -r pane; do
            if [ "$(get_pane_option "$pane" @is_center)" = "1" ]; then
                center_pane="$pane"
                break
            fi
        done < <(tmux list-panes -F '#{pane_id}')

        # Create terminal pane above center
        tmux split-window -vb -t "$center_pane" -l '25%' -c "#{pane_current_path}"
        local new_terminal
        new_terminal="$(tmux display-message -p '#{pane_id}')"
        tag_terminal "$new_terminal"
        notify "Created terminal pane"
    fi

    auto_layout

    # Mark that layout has been applied to prevent auto-trigger from happening again
    local current_window
    current_window=$(tmux display-message -p '#{window_index}')
    tmux set-option -w -t ":$current_window" @team_layout_auto_applied "1"
}

# =====================================================================
# Main
# =====================================================================

team

# Always exit successfully to prevent tmux error popups
exit 0

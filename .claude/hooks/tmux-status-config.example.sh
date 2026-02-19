# Example configuration for tmux-status.sh
#
# To customize colors, set these environment variables in your shell profile
# (e.g., ~/.zshrc, ~/.bashrc, or ~/.profile)
#
# Then restart your terminal or run: source ~/.zshrc

# ============================================================================
# Example 1: Minimal/Subtle Colors
# ============================================================================
# export CLAUDE_COLOR_PROCESSING="blue"
# export CLAUDE_COLOR_PROCESSING_CURRENT="blue,bold"
# export CLAUDE_COLOR_FINISHED="default"
# export CLAUDE_COLOR_FINISHED_CURRENT="default"
# export CLAUDE_COLOR_WAITING="yellow"
# export CLAUDE_COLOR_WAITING_CURRENT="yellow,bold"

# ============================================================================
# Example 2: High Contrast (Bright Colors)
# ============================================================================
# export CLAUDE_COLOR_PROCESSING="brightcyan"
# export CLAUDE_COLOR_PROCESSING_CURRENT="brightcyan,bold"
# export CLAUDE_COLOR_FINISHED="brightgreen"
# export CLAUDE_COLOR_FINISHED_CURRENT="brightgreen,bold"
# export CLAUDE_COLOR_WAITING="brightred"
# export CLAUDE_COLOR_WAITING_CURRENT="brightred,bold"

# ============================================================================
# Example 3: Monochrome (No Colors)
# ============================================================================
# export CLAUDE_COLOR_PROCESSING="default"
# export CLAUDE_COLOR_PROCESSING_CURRENT="reverse"      # Inverse video
# export CLAUDE_COLOR_FINISHED="default"
# export CLAUDE_COLOR_FINISHED_CURRENT="dim"            # Dimmed
# export CLAUDE_COLOR_WAITING="default"
# export CLAUDE_COLOR_WAITING_CURRENT="underscore"      # Underlined

# ============================================================================
# Available Colors
# ============================================================================
# Standard: black, red, green, yellow, blue, magenta, cyan, white, default
# Bright:   brightred, brightgreen, brightblue, brightmagenta, brightcyan, etc.
#
# Available Modifiers (can combine with commas):
#   bold, dim, underscore, blink, reverse, hidden
#
# Examples:
#   "red,bold"
#   "brightblue,underscore"
#   "default,reverse,bold"

# ============================================================================
# Current Defaults (if not overridden)
# ============================================================================
# CLAUDE_COLOR_PROCESSING=cyan             # User input being processed
# CLAUDE_COLOR_PROCESSING_CURRENT=cyan,bold
#
# CLAUDE_COLOR_FINISHED=green              # Claude finished working
# CLAUDE_COLOR_FINISHED_CURRENT=green,bold
#
# CLAUDE_COLOR_WAITING=red                 # Waiting for permission/teammate
# CLAUDE_COLOR_WAITING_CURRENT=red,bold
#
# CLAUDE_COLOR_DEFAULT=default             # Session ended or /done called
# CLAUDE_COLOR_DEFAULT_CURRENT=default

# Claude Hooks for Tmux Integration

This directory contains hooks that integrate Claude Code with tmux to provide visual feedback about Claude's state through window color changes.

## Files

- **tmux-status.sh** - Main hook script that changes tmux window colors based on Claude events
- **tmux-status-config.example.sh** - Example configuration showing how to customize colors

## How It Works

The hook script is triggered by various Claude events (configured in `~/.claude/settings.json`) and changes the tmux window background color to indicate Claude's current state:

| Event | Default Color | Meaning |
|-------|---------------|---------|
| UserPromptSubmit | Deep Blue (white text) | Processing your input |
| PreToolUse | Deep Blue (white text) | Working with tools |
| Stop | Deep Green (white text) | Finished and idle |
| Stop (with /done) | Default | Task completed, reset state |
| PermissionRequest | Dark Orange (white text) | Waiting for your permission |
| TeammateIdle | Dark Orange (white text) | Teammate is idle |
| SessionEnd | Default | Session ended |

## Customizing Colors

You can customize the colors by setting environment variables in your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
# Example: Use simple cyan instead of bright blue with high contrast
export CLAUDE_COLOR_PROCESSING="bg=cyan"
export CLAUDE_COLOR_PROCESSING_CURRENT="bg=cyan,bold"

# Example: Use red for waiting states instead of bright yellow
export CLAUDE_COLOR_WAITING="fg=white,bg=red"
export CLAUDE_COLOR_WAITING_CURRENT="fg=white,bg=red,bold"
```

See `tmux-status-config.example.sh` for more examples and available color options.

## Available Environment Variables

- `CLAUDE_COLOR_PROCESSING` - Color when processing user input (default: fg=white,bg=colour21)
- `CLAUDE_COLOR_PROCESSING_CURRENT` - Color for current/active window when processing (default: fg=white,bg=colour21,bold)
- `CLAUDE_COLOR_FINISHED` - Color when Claude is finished (default: fg=white,bg=colour22)
- `CLAUDE_COLOR_FINISHED_CURRENT` - Color for current/active window when finished (default: fg=white,bg=colour22,bold)
- `CLAUDE_COLOR_WAITING` - Color when waiting for user action (default: fg=white,bg=colour94)
- `CLAUDE_COLOR_WAITING_CURRENT` - Color for current/active window when waiting (default: fg=white,bg=colour94,bold)
- `CLAUDE_COLOR_DEFAULT` - Default/reset color (default: default)
- `CLAUDE_COLOR_DEFAULT_CURRENT` - Default color for current/active window (default: default)

## Logs

All hook events are logged to `~/.claude/hook.log` with format:
```
[timestamp] win:N EventType -> action
```

Example:
```
[2026-02-17 18:21:33] win:4 UserPromptSubmit -> blue (processing)
[2026-02-17 18:21:36] win:4 Stop -> default (done)
```

## The /done Command

Use `/done` in Claude to signal task completion. This will reset the window color to default instead of green, indicating you're explicitly done with a task.

## Troubleshooting

**Colors not changing:**
- Ensure you're running inside tmux
- Check `~/.claude/hook.log` for errors
- Verify hooks are configured in `~/.claude/settings.json`

**Wrong colors:**
- Check if environment variables are set: `env | grep CLAUDE_COLOR`
- Restart your terminal after changing environment variables

**Multiple Claude sessions interfering:**
- Each window has independent state - they won't interfere with each other

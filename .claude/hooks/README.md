# Claude Hooks for Tmux Integration

This directory contains hooks that integrate Claude Code with tmux to provide visual feedback and automatic layout management.

## Files

- **tmux-color.sh** - Manages tmux window colors based on Claude state (processing, blocked, finished)
- **tmux-layout.sh** - Automatically reorganizes tmux panes for Claude Code teams
- **tmux-status-config.example.sh** - Example configuration showing how to customize colors

## How It Works

The hook scripts are triggered by various Claude events (configured in `~/.claude/settings.json`).

### Color Management (tmux-color.sh)

Changes the tmux window background color to indicate Claude's current state:

| Event | Default Color | Meaning |
|-------|---------------|---------|
| UserPromptSubmit | Deep Blue (colour21) | Processing your input |
| PreToolUse | Deep Blue (colour21) | Working with tools |
| Stop | Deep Green (colour22) | Finished and idle |
| Stop (with /done) | Default | Task completed, reset state |
| PermissionRequest | Dark Red (colour88) | **Blocked** - waiting for your permission |
| SessionEnd | Default | Session ended |
| SubagentStop | Default (if blocked) | Agent stopped, cleared blocking state |
| IdlePrompt | Clears blocking | Permission was handled |

### Blocking State Mechanism

The script uses a **counter-based blocking state** (`@claude_blocking_count` tmux window option) to handle permission requests reliably, including multiple simultaneous requests from different agents:

1. **PermissionRequest** increments the counter and turns the window **red** (colour88)
2. The red color **persists** even through `Stop` and `PreToolUse` events, ensuring the user sees the window needs attention
3. Counter is **decremented** by (one permission resolved):
   - **IdlePrompt** - one permission was handled, agent is idle
   - **SubagentStop** - one agent that may have needed permission has stopped
4. Counter is **reset to 0** by (full clear):
   - **UserPromptSubmit** - user responded, clears all blocking
   - **SessionEnd** - session ended entirely
5. Window stays red as long as counter > 0

This counter-based design handles the multi-agent scenario where multiple agents request permissions simultaneously - one agent's resolution won't prematurely clear another agent's blocking state.

### Team Layout Management (tmux-layout.sh)

When using Claude Code teams (multiple agents), this script automatically manages pane layout:

- **TeammateIdle** triggers automatic layout reorganization into a 3-column structure (via `~/.tmux/team-layout.sh`), but only once per team session
- **SubagentStop** resets to a 2-pane layout (via `~/.tmux/reset-layout.sh`) when agent count drops to 2
- **SessionEnd** clears the auto-applied flag for next session

### Known Limitation: Window-Level Tracking

The blocking counter is tracked at the **tmux window level**, not per-agent. The counter-based approach improves multi-agent handling (one agent's `IdlePrompt` decrements rather than fully clearing), but limitations remain:

- Claude hooks receive no agent-specific identifier, so the counter is a best-effort heuristic
- `UserPromptSubmit` resets the entire counter (not just one agent's contribution) since there's no way to know which agent was unblocked
- If an agent fires `IdlePrompt` for reasons unrelated to permission handling, the counter may be decremented incorrectly

## Customizing Colors

You can customize the colors by setting environment variables in your shell profile (`~/.zshrc`, `~/.bashrc`, etc.):

```bash
# Example: Use simple cyan instead of bright blue with high contrast
export CLAUDE_COLOR_PROCESSING="bg=cyan"
export CLAUDE_COLOR_PROCESSING_CURRENT="bg=cyan,bold"

# Example: Use bright red for waiting states
export CLAUDE_COLOR_WAITING="fg=white,bg=red"
export CLAUDE_COLOR_WAITING_CURRENT="fg=white,bg=red,bold"
```

See `tmux-status-config.example.sh` for more examples and available color options.

## Available Environment Variables

- `CLAUDE_COLOR_PROCESSING` - Color when processing user input (default: fg=white,bg=colour21)
- `CLAUDE_COLOR_PROCESSING_CURRENT` - Color for current/active window when processing (default: fg=white,bg=colour21,bold)
- `CLAUDE_COLOR_FINISHED` - Color when Claude is finished (default: fg=white,bg=colour22)
- `CLAUDE_COLOR_FINISHED_CURRENT` - Color for current/active window when finished (default: fg=white,bg=colour22,bold)
- `CLAUDE_COLOR_WAITING` - Color when waiting for user action (default: fg=white,bg=colour88)
- `CLAUDE_COLOR_WAITING_CURRENT` - Color for current/active window when waiting (default: fg=white,bg=colour88,bold)
- `CLAUDE_COLOR_DEFAULT` - Default/reset color (default: default)
- `CLAUDE_COLOR_DEFAULT_CURRENT` - Default color for current/active window (default: default)

## Logs

Hook events are logged to separate files:

- `~/.claude/color.log` - Color management events (tmux-color.sh)
- `~/.claude/layout.log` - Layout management events (tmux-layout.sh)

Log format: `[timestamp] win:N EventType -> action`

Example (color.log):
```
[2026-02-17 18:21:33] win:4 UserPromptSubmit -> blue (processing)
[2026-02-17 18:21:36] win:4 Stop -> default (done)
[2026-02-17 18:22:01] win:4 PermissionRequest -> red (waiting x1)
[2026-02-17 18:22:03] win:4 PermissionRequest -> red (waiting x2)
[2026-02-17 18:22:05] win:4 Stop -> (blocked x2, not clearing)
[2026-02-17 18:22:07] win:4 IdlePrompt -> (permission granted, still blocked x1)
[2026-02-17 18:22:10] win:4 UserPromptSubmit -> blue (processing)
```

Example (layout.log):
```
[2026-02-24 20:45:12] win:5 TeammateIdle -> (triggering team layout)
[2026-02-24 20:50:33] win:5 SubagentStop -> (resetting to 2-pane layout)
```

## The /done Command

Use `/done` in Claude to signal task completion. This will reset the window color to default instead of green, indicating you're explicitly done with a task. The mechanism uses the `@claude_done` tmux window option, set by the `/done` skill and read by the `Stop` handler.

## Troubleshooting

**Colors not changing:**
- Ensure you're running inside tmux
- Check `~/.claude/color.log` for errors
- Verify hooks are configured in `~/.claude/settings.json`

**Wrong colors:**
- Check if environment variables are set: `env | grep CLAUDE_COLOR`
- Restart your terminal after changing environment variables

**Multiple Claude sessions interfering:**
- Each window has independent state via tmux window options - they won't interfere with each other

**Window stays red after permission is granted:**
- This can happen if the clearing event (`IdlePrompt` or `UserPromptSubmit`) fires for a different window
- Check `~/.claude/color.log` to see which events fired and for which window
- As a workaround, submitting any prompt in the affected window will clear the state

**Team layout not triggering:**
- Layout auto-applies once per team session (tracked by `@team_layout_auto_applied` window option)
- Manual trigger: `tmux run-shell ~/.tmux/team-layout.sh`
- Requires at least 3 panes (1 lead + 2+ agents)

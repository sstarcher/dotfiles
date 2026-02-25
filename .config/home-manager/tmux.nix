{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 0;  # Faster escape time for better responsiveness
    keyMode = "vi";
    terminal = "screen-256color";
    historyLimit = 100000;
    mouse = false;

    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.pain-control
      tmuxPlugins.yank
      tmuxPlugins.vim-tmux-navigator
      {
        plugin = tmuxPlugins.prefix-highlight;
        extraConfig = ''
          # Color definitions for prefix-highlight (must be set before plugin loads)
          color_dark="colour232"
          color_secondary="colour134"

          set -g @prefix_highlight_output_prefix '['
          set -g @prefix_highlight_output_suffix ']'
          set -g @prefix_highlight_fg "$color_dark"
          set -g @prefix_highlight_bg "$color_secondary"
          set -g @prefix_highlight_show_copy_mode 'on'
          set -g @prefix_highlight_copy_mode_attr "fg=$color_dark,bg=$color_secondary"
          set -g @prefix_highlight_prefix_prompt 'PREFIX'
          set -g @prefix_highlight_copy_prompt 'COPY'
        '';
      }
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-processes 'claude "~claude --*->claude" htop "~watch"'
          set -g @resurrect-save 'F5'
          set -g @resurrect-restore 'F6'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '30' # minutes
        '';
      }
    ];

    extraConfig = ''
      # ==========================
      # ===  General settings  ===
      # ==========================
      setw -g automatic-rename off
      setw -g allow-rename off
      set -g renumber-windows on
      set -g remain-on-exit off
      set -g repeat-time 300
      setw -g aggressive-resize on
      set -g display-time 1500
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Set terminal title
      set -g set-titles on
      set -g set-titles-string "#I:#W"

      # OSC 52 clipboard integration for nested sessions
      set -g allow-passthrough on
      set -g set-clipboard on
      set -as terminal-overrides ',*:Ms=\E]52;c;%p2%s\007'

      # Auto-update SSH environment when reattaching
      set-hook -g client-attached 'run-shell "tmux set-environment SSH_TTY #{client_tty}; if [ -n \"$SSH_AUTH_SOCK\" ]; then tmux set-environment SSH_AUTH_SOCK $SSH_AUTH_SOCK; fi"'

      # ===========================
      # ===   Key bindings      ===
      # ===========================

      # Reload config
      bind C-r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

      # New window retaining current directory
      bind c new-window -c "#{pane_current_path}"
      bind -n C-t new-window -c "#{pane_current_path}"

      # Rename session and window
      bind r command-prompt -I "#{window_name}" "rename-window '%%'"
      bind R command-prompt -I "#{session_name}" "rename-session '%%'"

      # Split panes with | and _ (more intuitive than % and ")
      unbind %
      unbind '"'
      bind | split-window -h -c "#{pane_current_path}"
      bind _ split-window -v -c "#{pane_current_path}"

      # Pane resize shortcuts
      bind-key J resize-pane -D 5
      bind-key K resize-pane -U 5
      bind-key H resize-pane -L 5
      bind-key L resize-pane -R 5

      # Select panes
      bind -r [ select-pane -t :.-
      bind -r ] select-pane -t :.+

      # Swap panes
      bind -r C-o swap-pane -D
      bind \\ if '[ #{pane_index} -eq 1 ]' \
           'swap-pane -s "!"' \
           'select-pane -t:.1 ; swap-pane -d -t 1 -s "!"'

      # Window navigation
      bind -n C-p previous-window
      bind -n C-n next-window
      bind -r Tab last-window

      # Move windows
      bind-key -n M-p swap-window -t -1 \; previous-window
      bind-key -n M-n swap-window -t +1 \; next-window

      # Zoom pane
      bind + resize-pane -Z

      # Kill shortcuts
      bind x kill-window
      bind C-x confirm-before -p "kill other windows? (y/n)" "kill-window -a"
      bind Q confirm-before -p "kill-session #S? (y/n)" kill-session

      # Merge session windows
      bind C-u command-prompt -p "Session to merge with: " \
         "run-shell 'yes | head -n #{session_windows} | xargs -I {} -n 1 tmux movew -t %%'"

      # Detach
      bind d detach
      bind D if -F '#{session_many_attached}' \
          'confirm-before -p "Detach other clients? (y/n)" "detach -a"' \
          'display "Session has only 1 client attached"'

      # Toggle status bar
      bind C-s if -F '#{s/off//:status}' 'set status off' 'set status on'

      # Monitor window for activity/silence
      bind m setw monitor-activity \; display-message 'Monitor window activity [#{?monitor-activity,ON,OFF}]'
      bind M if -F '#{monitor-silence}' \
          'setw monitor-silence 0 ; display-message "Monitor window silence [OFF]"' \
          'command-prompt -p "Monitor silence: interval (s)" "setw monitor-silence %%"'

      set -g visual-activity on

      # ================================================
      # ===     Copy mode, scroll and clipboard      ===
      # ================================================

      # Trigger copy mode
      bind -n C-u copy-mode

      # Vi-style selection
      unbind-key -T copy-mode-vi v
      bind-key -T copy-mode-vi v send -X begin-selection
      bind-key -T copy-mode-vi C-v send -X rectangle-toggle

      # Enhanced scrolling in copy mode
      bind -T copy-mode-vi M-Up              send-keys -X scroll-up
      bind -T copy-mode-vi M-Down            send-keys -X scroll-down
      bind -T copy-mode-vi M-PageUp          send-keys -X halfpage-up
      bind -T copy-mode-vi M-PageDown        send-keys -X halfpage-down
      bind -T copy-mode-vi PageDown          send-keys -X page-down
      bind -T copy-mode-vi PageUp            send-keys -X page-up

      # Mouse wheel scroll speed (10 lines at a time)
      bind -T copy-mode-vi WheelUpPane       select-pane \; send-keys -X -N 10 scroll-up
      bind -T copy-mode-vi WheelDownPane     select-pane \; send-keys -X -N 10 scroll-down

      # Copy shortcuts
      bind p paste-buffer
      bind C-p choose-buffer

      # Y copies whole line, D copies to end of line
      bind -T copy-mode-vi Y send-keys -X copy-line
      bind-key -T copy-mode-vi D send-keys -X copy-end-of-line

      # Copy on drag end, but don't cancel copy mode
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe
      bind -T copy-mode-vi MouseDown1Pane select-pane \; send-keys -X clear-selection

      # =====================================
      # ===   Nested Sessions Support     ===
      # =====================================

      # Color definitions
      color_orange="colour166"
      color_purple="colour134"
      color_green="colour076"
      color_blue="colour39"
      color_yellow="colour220"
      color_red="colour160"
      color_black="colour232"
      color_white="white"

      color_dark="$color_black"
      color_light="$color_white"
      color_main="$color_orange"
      color_secondary="$color_purple"
      color_status_text="colour245"
      color_window_off_indicator="colour088"
      color_window_off_status_bg="colour238"
      color_window_off_status_current_bg="colour254"

      # Powerline separators
      separator_powerline_left=""
      separator_powerline_right=""

      # F12 (or C-f) to toggle local session on/off (for nested sessions)
      bind -T root F12  \
          set prefix None \;\
          set key-table off \;\
          set status-style "fg=$color_status_text,bg=$color_window_off_status_bg" \;\
          set window-status-current-format "#[fg=$color_window_off_status_bg,bg=$color_window_off_status_current_bg]$separator_powerline_right#[fg=$color_window_off_status_bg] #I:#W #[fg=$color_window_off_status_current_bg,bg=$color_window_off_status_bg]$separator_powerline_right#[default]" \;\
          set window-status-current-style "fg=$color_dark,bold,bg=$color_window_off_status_current_bg" \;\
          if -F '#{pane_in_mode}' 'send-keys -X cancel' \;\
          refresh-client -S

      bind -T off F12 \
        set -u prefix \;\
        set -u key-table \;\
        set -u status-style \;\
        set -u window-status-current-style \;\
        set -u window-status-current-format \;\
        refresh-client -S

      # =====================================
      # ===   Pane styling                ===
      # =====================================

      # Pane borders - dim inactive pane borders
      set -g pane-border-style "fg=colour235"
      set -g pane-active-border-style "fg=colour245"

      # Dim inactive panes significantly
      set -g window-style "fg=colour240,bg=colour234"
      set -g window-active-style "fg=colour250,bg=colour232"

      # =====================================
      # ===   Status line                 ===
      # =====================================

      set -g status on
      set -g status-interval 10
      set -g status-position bottom
      set -g status-justify left

      # Status bar colors - simplified for Claude hook management
      set -g status-style "fg=colour245,bg=colour232"

      # Window status format (non-active windows)
      set -g window-status-format " #I:#W "

      # Active window format - use brackets instead of background color
      set -g window-status-current-format " [#I:#W] "

      # Window separator
      set -g window-status-separator ""

      # Note: Window status colors are dynamically managed by Claude hooks
      # See ~/.claude/hooks/tmux-status.sh for color management

      # Status bar left and right - prefix/copy mode indicator shown first
      set -g status-left "#{prefix_highlight} [#{session_name}]"
      set -g status-left-length 40

      set -g status-right "%H:%M %d-%b-%y"
      set -g status-right-length 40

      # =====================================
      # ===   Plugin Configuration        ===
      # =====================================
      # (Prefix highlight config moved to plugin definition above)

      # =====================================
      # ===   Environment Updates         ===
      # =====================================

      set -g update-environment \
        "DISPLAY\
        SSH_ASKPASS\
        SSH_AUTH_SOCK\
        SSH_AGENT_PID\
        SSH_CONNECTION\
        SSH_TTY\
        WINDOWID\
        XAUTHORITY"

      # =====================================
      # ===   Claude Agent Layouts        ===
      # =====================================
      # Bindings for managing Claude Code multi-agent team pane layouts.
      # NOTE: K overrides resize-pane-up (use H/J/L or arrow keys for resize)
      # NOTE: r overrides rename-window (use prefix+, to rename instead)
      # NOTE: R overrides rename-session

      # Kill all other panes (keep only current)
      bind K run-shell "tmux kill-pane -a"

      # AI Agents layout (3 left | 2 center | 3 right)
      bind A split-window -h -p 75 \; \
             split-window -h -p 66 \; \
             select-pane -t 0 \; split-window -v \; split-window -v \; \
             select-pane -t 3 \; split-window -v \; \
             select-pane -t 5 \; split-window -v \; split-window -v \; \
             select-pane -t 3

      # Team layout reorganizer (reorganize existing panes into 3-column structure)
      # Also triggers automatically via Claude hooks (TeammateIdle)
      bind t run-shell '~/.tmux/team-layout.sh'

      # Reset to 2-pane layout
      # Also triggers automatically via Claude hooks (SubagentStop when panes drop to 2)
      bind r run-shell '~/.tmux/reset-layout.sh'

      # Reset auto-layout flag (allow automatic reorganization to trigger again)
      bind R set-option -wu @team_layout_auto_applied \; display-message "Auto-layout re-enabled"
    '';
  };
}

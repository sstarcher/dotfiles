{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    escapeTime = 10;
    keyMode = "vi";
    terminal = "screen-256color";
    historyLimit = 100000;
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.pain-control
      tmuxPlugins.yank
      tmuxPlugins.vim-tmux-navigator
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '60' # minutes
        '';
      }
    ];
    extraConfig = ''
      setw -g automatic-rename on
      set -g renumber-windows on
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Status bar
      set -g status-style "bg=black,fg=white"
      set -g status-left-style "bg=black,fg=white"
      set -g status-right-style "bg=black,fg=white"
      set -g window-status-current-style "bg=black,fg=green"

      # Visual indicator for prefix and copy mode
      set -g status-left "#{?client_prefix,#[bg=yellow#,fg=black] PREFIX ,#{?pane_in_mode,#[bg=magenta#,fg=white] COPY ,#[bg=black#,fg=white] #S }}"
      set -g status-left-length 20

      # Dim inactive panes
      set -g window-style "fg=colour245,bg=colour236"
      set -g window-active-style "fg=colour255,bg=black"

      # Pane borders
      set -g pane-border-style "fg=white"
      set -g pane-active-border-style "#{?pane_in_mode,fg=magenta,fg=cyan}"
      set -g pane-border-format " #{pane_index} #{pane_title} "
      set -g pane-border-status off
    '';
  };
}

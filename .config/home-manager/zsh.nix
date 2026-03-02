{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    # History settings
    history = {
      size = 10000;
      save = 10000;
      path = "${config.home.homeDirectory}/.histfile";
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    # Shell options
    defaultKeymap = "emacs";  # Use emacs mode (standard readline bindings)

    # Plugins
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.zsh-syntax-highlighting;
        file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      }
    ];

    # Environment variables
    sessionVariables = {
      HELM_PLUGINS = "$HOME/.local/share/helm/plugins";
      VISUAL = "vim";
      EDITOR = "vim";
      TERMINAL = "urxvtc";
      GOPATH = "$HOME/go";
      GO111MODULE = "auto";
      PIPENV_MAX_DEPTH = "5";
      SSH_AUTH_SOCK = "~/.ssh/ssh-agent.nix-old.sock";
      ZSH_HIGHLIGHT_MAXLENGTH = "200";
      KUBECTL_EXTERNAL_DIFF = "dyff between --exclude=metadata.annotations.argocd.argoproj.io/tracking-id --set-exit-code --omit-header \"$1\" \"$2\"";
    };

    # Completion configuration
    completionInit = ''
      autoload -U compinit && compinit
      zstyle :compinstall filename "$HOME/.zshrc"
    '';

    # Shell initialization using new initContent API
    initContent = lib.mkMerge [
      # Early initialization (runs before compinit)
      (lib.mkOrder 550 ''
        # devbox initialization (must run first)
        if command -v devbox &> /dev/null; then
          eval "$(devbox global shellenv --init-hook)"

          # Apply home-manager config only if changed (avoid unnecessary rebuilds)
          HM_MARKER="$HOME/.local/state/home-manager/.last-switch-ts"
          if [ ! -f "$HM_MARKER" ] || [ ~/.config/home-manager -nt "$HM_MARKER" ]; then
            home-manager switch &>/dev/null &!
            touch "$HM_MARKER"
          fi
        fi

        # Enable Powerlevel10k instant prompt
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      # Main initialization (runs after compinit)
      ''
        # Shell options
        setopt AUTO_CD

        # GPG TTY
        export GPG_TTY=$(tty)

        # PATH additions
        export PATH="$GOPATH/bin:$PATH"
        export PATH="$PATH:$HOME/.stuff/bin/"
        export PATH="$PATH:$HOME/.local/bin"

        # Terminal Title (iTerm and tmux)
        precmd() {
          # iTerm title
          echo -ne "\033];''${''${PWD##*/}: -15}\007"

          # tmux window title
          if [ -n "$TMUX" ]; then
            REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
            if [ -n "$REPO_ROOT" ]; then
              REPO_NAME=$(basename "$REPO_ROOT")
              if [ "$REPO_ROOT" = "$PWD" ]; then
                # At git root, show only repo name
                tmux rename-window "''${REPO_NAME}"
              else
                # In a subdirectory, show both
                CURRENT_DIR=$(basename "$PWD")
                tmux rename-window "''${REPO_NAME}/''${CURRENT_DIR}"
              fi
            else
              tmux rename-window "$(basename "$PWD")"
            fi
          fi
        }

        # iTerm integration
        if [ $ITERM_SESSION_ID ]; then
          DISABLE_AUTO_TITLE="true"
          precmd
        fi

        # Source aliases and secrets
        source ~/.stuff/aliases
        if [ -f ~/.stuff/secret ]; then
          source ~/.stuff/secret
        fi
        if [ -f ~/.secret_secret ]; then
          source ~/.secret_secret
        fi

        # Powerlevel10k configuration
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        # scmpuff (git index shortcuts)
        eval "$(scmpuff init -s)"

        # Source user dotfiles
        if [ -f "/home/coder/.zshrc.user" ]; then
          source "/home/coder/.zshrc.user"
        fi

        # Source lightspeed aliases
        if [ -f "/home/coder/lightspeed/infrastructure/shared/k8s-builder/files/.bash_aliases" ]; then
          source "/home/coder/lightspeed/infrastructure/shared/k8s-builder/files/.bash_aliases"
        fi

        # Load FZF at the very end to ensure bindings work
        if command -v fzf &>/dev/null && [[ -o interactive ]]; then
          eval "$(fzf --zsh)"
        fi
      ''
    ];
  };
}

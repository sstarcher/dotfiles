{ config, pkgs, lib, ... }:

{
  # Install zsh packages but don't manage .zshrc
  # This allows the system .zshrc to remain untouched
  home.packages = with pkgs; [
    zsh-powerlevel10k
    zsh-syntax-highlighting
    zsh-autosuggestions
  ];


  # Manage .zshrc.user instead of .zshrc
  home.file.".zshrc.user".text = ''
    # Managed by home-manager
    # This file is sourced by the system .zshrc

    # devbox initialization (before p10k instant prompt to avoid console output warnings)
    if command -v devbox &> /dev/null; then
      eval "$(devbox global shellenv --init-hook 2>/dev/null)"

      # Apply home-manager config only if changed (avoid unnecessary rebuilds)
      HM_MARKER="$HOME/.local/state/home-manager/.last-switch-ts"
      if [ ! -f "$HM_MARKER" ] || [ -n "$(find ~/.config/home-manager -newer "$HM_MARKER" -name '*.nix' 2>/dev/null)" ]; then
        home-manager switch &>/dev/null &!
        touch "$HM_MARKER"
      fi
    fi

    # Enable Powerlevel10k instant prompt (after devbox to avoid console output warnings)
    if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
      source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
    fi

    # History settings
    HISTSIZE=10000
    SAVEHIST=10000
    HISTFILE=~/.histfile
    setopt SHARE_HISTORY
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_SPACE

    # Shell options
    setopt AUTO_CD

    # Completion
    autoload -U compinit && compinit -C
    zstyle :compinstall filename "$HOME/.zshrc"

    # GPG TTY
    export GPG_TTY=$(tty)

    # Environment variables
    export HELM_PLUGINS="$HOME/.local/share/helm/plugins"
    export VISUAL="vim"
    export EDITOR="vim"
    export GOPATH="$HOME/go"
    export GO111MODULE="auto"
    export PIPENV_MAX_DEPTH="5"
    export ZSH_HIGHLIGHT_MAXLENGTH="200"
    export KUBECTL_EXTERNAL_DIFF="dyff between --exclude=metadata.annotations.argocd.argoproj.io/tracking-id --set-exit-code --omit-header \"$1\" \"$2\""

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

    # Load Powerlevel10k theme
    if [ -d "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k" ]; then
      source "${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme"
    fi

    # Load autosuggestions
    if [ -d "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions" ]; then
      source "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi

    # Load syntax highlighting
    if [ -d "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting" ]; then
      source "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    fi

    # Source aliases and secrets
    [ -f ~/.stuff/aliases ] && source ~/.stuff/aliases
    [ -f ~/.stuff/secret ] && source ~/.stuff/secret
    [ -f ~/.secret_secret ] && source ~/.secret_secret

    # Powerlevel10k configuration
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

    # scmpuff (git index shortcuts)
    if command -v scmpuff &>/dev/null; then
      eval "$(scmpuff init -s)"
    fi

    # Load FZF at the very end to ensure bindings work
    if command -v fzf &>/dev/null && [[ -o interactive ]]; then
      eval "$(fzf --zsh)"
    fi
  '';
}

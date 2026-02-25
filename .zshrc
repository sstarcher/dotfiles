
export HELM_PLUGINS="$HOME/.local/share/helm/plugins"
if command -v devbox &> /dev/null; then
  eval "$(devbox global shellenv --init-hook)"

  # Apply home-manager config only if changed (avoid unnecessary rebuilds)
  HM_MARKER="$HOME/.local/state/home-manager/.last-switch-ts"
  if [ ! -f "$HM_MARKER" ] || [ ~/.config/home-manager -nt "$HM_MARKER" ]; then
    home-manager switch &>/dev/null &!
    touch "$HM_MARKER"
  fi

  source $(devbox global path)/.devbox/nix/profile/default/share/antidote/antidote.zsh
  antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi



HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE



# The following lines were added by compinstall
zstyle :compinstall filename "$HOME/.zshrc"
autoload -U compinit && compinit
# End of lines added by compinstall

setopt AUTO_CD

ZSH_HIGHLIGHT_MAXLENGTH=200

export \
        VISUAL=vim \
        EDITOR=vim \
        TERMINAL=urxvtc

# Go
export GOPATH=$HOME/go
export GO111MODULE=auto
export PATH=$GOPATH/bin:$PATH

# gpg keychain
export GPG_TTY=$(tty)

# Terminal Title (iTerm and tmux)
precmd() {
  # iTerm title
  echo -ne "\033];${${PWD##*/}: -15}\007"

  # tmux window title
  if [ -n "$TMUX" ]; then
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -n "$REPO_ROOT" ]; then
      REPO_NAME=$(basename "$REPO_ROOT")
      if [ "$REPO_ROOT" = "$PWD" ]; then
        # At git root, show only repo name
        tmux rename-window "${REPO_NAME}"
      else
        # In a subdirectory, show both
        CURRENT_DIR=$(basename "$PWD")
        tmux rename-window "${REPO_NAME}/${CURRENT_DIR}"
      fi
    else
      tmux rename-window "$(basename "$PWD")"
    fi
  fi
}

if [ $ITERM_SESSION_ID ]; then
  DISABLE_AUTO_TITLE="true"
  precmd
fi


PATH="$PATH:~/.stuff/bin/"
source ~/.stuff/aliases
if [ -f ~/.stuff/secret ]; then
    source ~/.stuff/secret
fi

PATH="$PATH:$HOME/.local/bin"
# zoxide is managed by home-manager (zoxide.nix)

# Python
export PIPENV_MAX_DEPTH=5

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


export KUBECTL_EXTERNAL_DIFF='dyff between \
      --exclude=metadata.annotations.argocd.argoproj.io/tracking-id \
      --set-exit-code --omit-header "$1" "$2"'

if [ -f ~/.secret_secret ]; then
    source ~/.secret_secret
fi

eval "$(scmpuff init -s)"
export SSH_AUTH_SOCK=~/.ssh/ssh-agent.nix-old.sock
# Load fzf key bindings at the VERY END to ensure nothing overrides Ctrl+r
# This must come after all plugins and configurations

# Custom fzf history search widget (works reliably)
fzf-history-search() {
  local selected
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases

  # Use fc to get history, format it, and pipe to fzf
  selected=$(fc -rl 1 | awk '{$1=""; print substr($0,2)}' | \
    fzf --height 40% \
        --layout=reverse \
        --border \
        --prompt='History> ' \
        --query="$LBUFFER" \
        --bind='ctrl-r:toggle-sort' \
        --tiebreak=index \
        --no-multi)

  local ret=$?
  if [ -n "$selected" ]; then
    LBUFFER="$selected"
  fi
  zle reset-prompt
  return $ret
}

# Register the widget and bind Ctrl+r to it
zle -N fzf-history-search
bindkey '^R' fzf-history-search

# Also try to load official fzf keybindings (for Ctrl+t and Alt+c)
if [ -f ~/.nix-profile/share/fzf/key-bindings.zsh ]; then
  source ~/.nix-profile/share/fzf/key-bindings.zsh 2>/dev/null
fi
if [ -f ~/.nix-profile/share/fzf/completion.zsh ]; then
  source ~/.nix-profile/share/fzf/completion.zsh 2>/dev/null
fi

if [ -f "/home/coder/.zshrc.user" ]; then source "/home/coder/.zshrc.user"; fi #user_dotfile
if [ -f "/home/coder/lightspeed/infrastructure/shared/k8s-builder/files/.bash_aliases" ]; then source "/home/coder/lightspeed/infrastructure/shared/k8s-builder/files/.bash_aliases"; fi #lightspeed_aliases

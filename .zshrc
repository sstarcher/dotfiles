
export HELM_PLUGINS="$HOME/.local/share/helm/plugins"
if command -v devbox &> /dev/null; then
  eval "$(devbox global shellenv --init-hook)"

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
eval "$(zoxide init zsh)"

# Python
export PIPENV_MAX_DEPTH=5

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

if [ -n "${commands[fzf-share]}" ]; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi

export KUBECTL_EXTERNAL_DIFF='dyff between \
      --exclude=metadata.annotations.argocd.argoproj.io/tracking-id \
      --set-exit-code --omit-header "$1" "$2"'

source ~/.secret_secret

eval "$(scmpuff init -s)"
export SSH_AUTH_SOCK=~/.ssh/ssh-agent.nix-old.sock
if [ -f "/home/coder/.zshrc.user" ]; then source "/home/coder/.zshrc.user"; fi #user_dotfile
if [ -f "/home/coder/lightspeed/infrastructure/shared/k8s-builder/files/.bash_aliases" ]; then source "/home/coder/lightspeed/infrastructure/shared/k8s-builder/files/.bash_aliases"; fi #lightspeed_aliases

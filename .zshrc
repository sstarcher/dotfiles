
if command -v devbox &> /dev/null; then
  eval "$(devbox global shellenv)"
fi

if [ -d "/home/linuxbrew" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  version=$(ls /home/linuxbrew/.linuxbrew/Cellar/antigen/ | head -n1)
  source /home/linuxbrew/.linuxbrew/Cellar/antigen/${version}/share/antigen/antigen.zsh
else
  source /usr/local/share/antigen/antigen.zsh
fi

# causes prompting and needs to be above P10K Instant Prompt
antigen init ~/.antigenrc

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
# End of lines configured by zsh-newuser-install

# The following lines were added by compinstall
zstyle :compinstall filename '/Users/sstarcher/.zshrc'
autoload -U compinit && compinit
# End of lines added by compinstall

setopt AUTO_CD

export TERM="xterm-256color"

ZSH_HIGHLIGHT_MAXLENGTH=200

# History
HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

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

# Iterm Title
precmd() {
  echo -ne "\033];${${PWD##*/}: -15}\007"
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

# export PATH="/usr/local/sbin:$PATH"
PATH="$PATH:$HOME/.local/bin"
eval "$(zoxide init zsh)"

# Python
export PIPENV_MAX_DEPTH=5

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export KUBECTL_EXTERNAL_DIFF="_kc_diff"


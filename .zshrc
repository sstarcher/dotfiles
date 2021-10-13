# causes prompting and needs to be above P10K Instant Prompt
source /usr/local/share/antigen/antigen.zsh
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

# Python
export \
        WORKON_HOME=~/.virtualenvs \
        PATH="/usr/local/opt/python@2/bin:$PATH" \
        PATH=/usr/local/bin:/usr/local/sbin:~/bin:$PATH \

# GNU Tools
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"

#GCloud
export PATH="$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/bin:$PATH"

# Go
export GOPATH=$HOME/go
export GO111MODULE=auto
export PATH=$GOPATH/bin:$PATH

# gpg keychain
export GPG_TTY=$(tty)

# Source chtf
if [[ -f /usr/local/share/chtf/chtf.sh ]]; then
    source "/usr/local/share/chtf/chtf.sh"
fi

# Source chtf
if [[ -f /usr/local/opt/chtf/share/chtf/chtf.sh ]]; then
    source "/usr/local/opt/chtf/share/chtf/chtf.sh"
fi

chtf 0.11.15



# Iterm Title
precmd() {
  echo -ne "\033];${${PWD##*/}: -15}\007"
}

if [ $ITERM_SESSION_ID ]; then
  DISABLE_AUTO_TITLE="true"
  precmd
fi

if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh)
fi

if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh



# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

source ~/.stuff/aliases
if [ -f ~/.stuff/secret ]; then
    source ~/.stuff/secret
fi

# Python
export PIPENV_MAX_DEPTH=5

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/shanestarcher/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/shanestarcher/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/shanestarcher/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/shanestarcher/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

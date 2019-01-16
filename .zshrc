source /usr/local/share/antigen/antigen.zsh
antigen init ~/.antigenrc

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/Users/sstarcher/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

setopt AUTO_CD

# Theme
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs )
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history virtualenv aws time )

POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
POWERLEVEL9K_SHORTEN_DELIMITER=''
POWERLEVEL9K_DIR_OMIT_FIRST_CHARACTER=true

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
        TERMINAL=urxvtc \
        BROWSER=google-chrome \

# Python
export \
        WORKON_HOME=~/.virtualenvs \
        VIRTUALENV_PYTHON=python2 \
        VIRTUALENVWRAPPER_PYTHON=/usr/local/opt/python@2/bin/python2 \
        PATH="/usr/local/opt/python@2/bin:$PATH" \
        PATH=/usr/local/bin:/usr/local/sbin:~/bin:$PATH \

# Go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# AWS
export AWS_PROFILE=prod

# gpg keychain
export GPG_TTY=$(tty)

# Source chtf
if [[ -f /usr/local/share/chtf/chtf.sh ]]; then
    source "/usr/local/share/chtf/chtf.sh"
fi

chtf 0.11.11


precmd() {
  echo -ne "\033];${${PWD##*/}: -15}\007"
}

# Iterm Title
if [ $ITERM_SESSION_ID ]; then
  DISABLE_AUTO_TITLE="true"
  precmd
fi

if [ $commands[kubectl] ]; then
  source <(kubectl completion zsh)
fi


source ~/.stuff/aliases
source ~/.stuff/secret

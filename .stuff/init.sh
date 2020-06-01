/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

brew bundle 

sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh
chsh -s /bin/zsh

# Pathogen
mkdir -p ~/.vim/autoload ~/.vim/bundle && \
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

# https://stackoverflow.com/questions/127591/using-caps-lock-as-esc-in-mac-os-x
# https://github.com/unixorn/awesome-zsh-plugins
# https://docs.docker.com/docker-for-mac/install/#download-docker-for-mac
# Change iterm fonts, remember directory

defaults write -g InitialKeyRepeat -int 20
defaults write -g KeyRepeat -int 3
defaults write com.apple.finder AppleShowAllFiles YES;

#iterm2
# Specify the preferences directory
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.iterm2"
# Tell iTerm2 to use the custom preferences in the directory
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true


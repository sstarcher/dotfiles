#!/bin/bash
set -euox pipefail

(
    cd /usr/share/fonts/truetype/
    sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
    sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
    sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
    sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
)

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

exit 0

export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin/"
brew bundle install --file ~/Brewfile

# Pathogen
mkdir -p ~/.vim/autoload ~/.vim/bundle && \
curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

if [ "$(uname)" != "Darwin" ]; then
    exit 0
fi

###############################################################################
### Run for Mac
###############################################################################

sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh
chsh -s /bin/zsh

# https://stackoverflow.com/questions/127591/using-caps-lock-as-esc-in-mac-os-x
# https://github.com/unixorn/awesome-zsh-plugins
# Change iterm fonts, remember directory

# Run mathiasbynes dotfiles
bash <(curl -fsSL https://raw.githubusercontent.com/mathiasbynens/dotfiles/master/.macos)

# Overrides for mathiasbynens's defaults
defaults write -g InitialKeyRepeat -int 20
defaults write -g KeyRepeat -int 3
defaults write com.apple.finder AppleShowAllFiles YES;

#iterm2
# Specify the preferences directory
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.iterm2"
# Tell iTerm2 to use the custom preferences in the directory
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

# Dock Settings
defaults write com.apple.dock tilesize -int 80

echo 'To install fonts run `p10k configure`'

while true; do
    read -p "Terminate everything?" yn
    case $yn in
        [Yy]* ) make install; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

###############################################################################
# Kill affected applications                                                  #
###############################################################################

for app in "Activity Monitor" \
	"Dock" \
	; do
	killall "${app}" &> /dev/null
done


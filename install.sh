#!/bin/bash
set -euo pipefail

if ! command -v devbox &> /dev/null; then
    curl -fsSL https://get.jetpack.io/devbox | FORCE=1 bash
fi

mkdir -p /home/coder/.local/share/devbox/global/default/.devbox/gen/scripts/
touch /home/coder/.local/share/devbox/global/default/.devbox/gen/scripts/.hooks.sh
eval "$(devbox global shellenv --init-hook)"

if ! command -v yadm &> /dev/null; then
    devbox global add yadm
fi

eval "$(devbox global shellenv --recompute)"

if [ ! -d "${HOME}/.local/share/yadm/repo.git" ]; then
    yadm clone https://github.com/sstarcher/dotfiles.git
    yadm diff > ~/.coder_diff
    yadm reset --hard
    eval "$(devbox global shellenv --recompute)"

    yadm remote rm origin
    yadm remote add origin git@github.com:sstarcher/dotfiles.git
fi

(
    cd /usr/share/fonts/truetype/
    sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
    sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
    sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
    sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
)

#NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

sudo ln -s /bin/zsh /usr/local/bin/zsh

home-manager switch

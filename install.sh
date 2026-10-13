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
    base="https://github.com/romkatv/powerlevel10k-media/raw/master"
    for font in "MesloLGS NF Regular.ttf" "MesloLGS NF Bold.ttf" \
                "MesloLGS NF Italic.ttf" "MesloLGS NF Bold Italic.ttf"; do
        # -O overwrites in place instead of leaving .ttf.1/.2/... duplicates on re-runs.
        [ -f "$font" ] || sudo wget -q -O "$font" "${base}/${font// /%20}"
    done
)

#NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

[ -e /usr/local/bin/zsh ] || sudo ln -s /bin/zsh /usr/local/bin/zsh

# Bootstrap home-manager if it isn't on PATH yet. This config uses the
# programs.claude-code / programs.codex / programs.mcp modules, which currently
# only exist in home-manager master (tracking nixpkgs-unstable), so pin both there.
if ! command -v home-manager &> /dev/null; then
    nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    export NIX_PATH="${HOME}/.nix-defexpr/channels${NIX_PATH:+:$NIX_PATH}"
    nix-shell '<home-manager>' -A install
fi

# -b backup moves pre-seeded files (e.g. ~/.aws/config, ~/.claude/settings.json)
# aside instead of aborting the first switch.
home-manager switch -b backup

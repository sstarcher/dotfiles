{ config, pkgs, ... }:

{
  imports = [
    ./tmux.nix
    ./git.nix
    ./zsh.nix
    ./fzf.nix
    ./zoxide.nix
  ] ++ (if builtins.pathExists ./work.nix then [ ./work.nix ] else [ ]);

  home.username = "coder";
  home.homeDirectory = "/home/coder";
  home.stateVersion = "24.11";
  home.enableNixpkgsReleaseCheck = false;

  home.packages = [
  ];

  home.file = {
    ".tmux/resurrect/.keep".text = "";
  };

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}

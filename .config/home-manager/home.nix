{ config, pkgs, ... }:

{
  imports = [
    ./tmux.nix
    ./git.nix
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
  };

  home.sessionVariables = {
  };

  programs.home-manager.enable = true;
}

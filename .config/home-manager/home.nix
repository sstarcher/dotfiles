{ config, pkgs, ... }:

{
  imports = [
    ./tmux.nix
  ];

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

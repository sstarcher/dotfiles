{ ... }:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;  # Manual integration in zsh.nix works, automatic doesn't
  };
}

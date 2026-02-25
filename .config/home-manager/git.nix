{ lib, ... }:
{
  programs.git = {
    enable = true;
    ignores = [
      ".claude"
      "*.code-workspace"
      ".env*"
      "*.pem"
      "*.key"
      ".secret*"
      "credentials.json"
    ];
    settings = {
      user = {
        name = "Shane Starcher";
        email = lib.mkDefault "shane.starcher@gmail.com";
      };
      alias.amend = "commit --amend --no-edit";
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      pull.ff = "only";
      color = {
        ui = true;
        diff = {
          new = "green";
          old = "red";
        };
      };
      init.defaultBranch = "master";
    };
  };
}

{ ... }:
{
  programs.git = {
    enable = true;
    signing.format = "openpgp";
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

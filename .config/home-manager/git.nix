{ ... }:
{
  programs.git = {
    enable = true;
    ignores = [
      ".claude"
    ];
    settings = {
      user = {
        name = "Shane Starcher";
        email = "shane.starcher@gmail.com";
      };
      alias.amend = "commit --amend --no-edit";
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      pull.ff = "only";
      core.sshcommand = "/usr/bin/ssh";
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

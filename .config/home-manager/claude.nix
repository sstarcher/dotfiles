{ ... }:
let
  claudeSettings = builtins.toJSON {
    env = {
      ANTHROPIC_DEFAULT_OPUS_MODEL = "us.anthropic.claude-opus-5-v1";
      ANTHROPIC_DEFAULT_SONNET_MODEL = "us.anthropic.claude-sonnet-5-v1";
      ANTHROPIC_SMALL_FAST_MODEL = "us.anthropic.claude-haiku-4-5-20251001-v1:0";
      ANTHROPIC_DEFAULT_HAIKU_MODEL = "us.anthropic.claude-haiku-4-5-20251001-v1:0";
    };
    permissions = {
      allow = [
        "Bash(sed *)"
        "Bash(grep *)"
        "Bash(ls *)"
        "Bash(diff *)"
        "Bash(echo *)"
        "Bash(wc *)"
        "Bash(head *)"
        "Bash(* | head *)"
        "Bash(cat *)"
        "Bash(tail *)"
        "Bash(* | tail *)"
        "Bash(jsonnet *)"
        "Bash(cd *)"
        "Bash(find *)"
        "Bash(jq *)"
        "Bash(git *)"
        "Bash(xxd *)"
        "Bash(* | xxd)"
        "Bash(* | xxd *)"
        "Bash(git * && echo * && git *)"
        "Bash(tail * && echo * && tail *)"
        "Bash(head * && echo * && head *)"
        "Bash(glab *)"
        "Bash(aws *)"
        "Bash(sleep *)"
        "Bash(mkdir *)"
        "Bash(gofmt *)"
      ];
    };
    model = "us.anthropic.claude-opus-5-v1";
    enabledMcpjsonServers = [
      "awslabs-aws-documentation-mcp-server"
      "k8s"
      "aws-knowledge-mcp-server"
      "awslabs.eks-mcp-server"
      "terraform"
    ];
    hooks = {
      SessionStart = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh SessionStart";
        }];
      }];
      Stop = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh Stop";
        }];
      }];
      UserPromptSubmit = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh UserPromptSubmit";
        }];
      }];
      SessionEnd = [{
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/tmux-color.sh SessionEnd";
          }
          {
            type = "command";
            command = "~/.claude/hooks/tmux-layout.sh SessionEnd";
          }
        ];
      }];
      PermissionRequest = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh PermissionRequest";
        }];
      }];
      PreToolUse = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh PreToolUse";
        }];
      }];
      PostToolUse = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh PostToolUse";
        }];
      }];
      PostToolUseFailure = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh PostToolUseFailure";
        }];
      }];
      Notification = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh IdlePrompt";
        }];
      }];
      SubagentStart = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh SubagentStart";
        }];
      }];
      SubagentStop = [{
        hooks = [
          {
            type = "command";
            command = "~/.claude/hooks/tmux-color.sh SubagentStop";
          }
          {
            type = "command";
            command = "~/.claude/hooks/tmux-layout.sh SubagentStop";
          }
        ];
      }];
      TeammateIdle = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-layout.sh TeammateIdle";
        }];
      }];
      TaskCompleted = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh TaskCompleted";
        }];
      }];
      PreCompact = [{
        hooks = [{
          type = "command";
          command = "~/.claude/hooks/tmux-color.sh PreCompact";
        }];
      }];
    };
    enabledPlugins = {
      "gopls-lsp@claude-plugins-official" = true;
    };
    autoUpdatesChannel = "latest";
    skipDangerousModePermissionPrompt = true;
  };
in
{
  home.file.".claude/settings.json" = {
    text = claudeSettings;
  };
}

{
  pkgs,
  module ? ../modules/devenv,
}:
let
  inherit (pkgs) lib;

  eval =
    extra:
    lib.evalModules {
      modules = [
        { _module.args = { inherit pkgs; }; }
        {
          options.enterShell = lib.mkOption {
            type = lib.types.lines;
            default = "";
          };
        }
        module
      ]
      ++ extra;
    };

  base = eval [ ];
  mcpOn = eval [ { agents.mcp.enable = true; } ];
  skillsOn = eval [ { agents.skills.review = ./fixtures/standalone; } ];
  serversWithoutEnable = eval [ { agents.mcp.servers.context7.command = "npx"; } ];
in
assert lib.assertMsg (!(base.options.agents ? enable)) "agents.enable must not exist";
assert lib.assertMsg (base.options.agents.mcp ? enable) "agents.mcp.enable must exist";
assert lib.assertMsg (base.config.enterShell == "") "empty import must not write a project hook";
assert lib.assertMsg (lib.hasInfix ".mcp.json" mcpOn.config.enterShell)
  "agents.mcp.enable must write project MCP files";
assert lib.assertMsg (
  !(lib.hasInfix ".mcp.json" serversWithoutEnable.config.enterShell)
) "filled servers without agents.mcp.enable must not write MCP files";
assert lib.assertMsg (lib.hasInfix ".agents/skills" skillsOn.config.enterShell)
  "a non-empty skills map must write skill dests";
pkgs.runCommand "eval-devenv-ok" { } "touch $out"

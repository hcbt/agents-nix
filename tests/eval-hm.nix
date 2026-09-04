{
  pkgs,
  catalog ? ../modules/home/catalog.nix,
}:
let
  inherit (pkgs) lib;

  stub = {
    options.programs.mcp = {
      enable = lib.mkEnableOption "mcp";
      servers = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = { };
      };
    };

    options.programs.grok = {
      enable = lib.mkEnableOption "grok";
      enableMcpIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      enableSkillsIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      enableContextIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      skills = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
      context = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.lines lib.types.path);
        default = null;
      };
    };

    options.programs.muse-code = {
      enable = lib.mkEnableOption "muse";
      enableMcpIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      enableSkillsIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      enableContextIntegration = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      skills = lib.mkOption {
        type = lib.types.attrs;
        default = { };
      };
      context = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.lines lib.types.path);
        default = null;
      };
    };
  };

  eval =
    extra:
    lib.evalModules {
      modules = [
        { _module.args = { inherit pkgs; }; }
        catalog
        stub
      ]
      ++ extra;
    };

  base = eval [ ];

  withMcp = eval [
    {
      agents.mcp.enable = true;
      agents.mcp.servers.context7.command = "npx";
    }
  ];

  serversWithoutEnable = eval [
    { agents.mcp.servers.context7.command = "npx"; }
  ];

  grokOn = eval [
    { programs.grok.enable = true; }
  ];

  grokInheritsSkills = eval [
    {
      programs.grok.enable = true;
      programs.grok.enableSkillsIntegration = true;
      agents.skills.review = ./fixtures/standalone;
    }
  ];
in
assert lib.assertMsg (
  base.options ? agents
) "catalogs must be declared at agents, not programs.agents";
assert lib.assertMsg (!(base.options.agents ? enable)) "agents.enable must not exist";
assert lib.assertMsg (base.options.agents.mcp ? enable) "agents.mcp.enable must exist";
assert lib.assertMsg (!base.config.agents.mcp.enable) "agents.mcp.enable defaults to false";
assert lib.assertMsg (!base.config.programs.mcp.enable) "empty import must not enable programs.mcp";
assert lib.assertMsg withMcp.config.programs.mcp.enable
  "agents.mcp.enable must assign programs.mcp.enable";
assert lib.assertMsg (
  withMcp.config.programs.mcp.servers ? context7
) "agents.mcp.servers must assign programs.mcp.servers";
assert lib.assertMsg (
  !serversWithoutEnable.config.programs.mcp.enable
) "filled servers without agents.mcp.enable must not assign programs.mcp";
assert lib.assertMsg (
  !grokOn.config.programs.grok.enableMcpIntegration
) "enabling grok must not set enableMcpIntegration";
assert lib.assertMsg (
  !grokOn.config.programs.grok.enableSkillsIntegration
) "enabling grok must not set enableSkillsIntegration";
assert lib.assertMsg (
  grokInheritsSkills.config.programs.grok.skills ? review
) "enableSkillsIntegration must inherit the skills catalog";
pkgs.runCommand "eval-hm-ok" { } "touch $out"

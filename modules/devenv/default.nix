{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.agents;
  agentsLib = import ../../lib { inherit lib; };

  skillEntryType = lib.types.either lib.types.path (
    lib.types.submodule {
      options = {
        path = lib.mkOption { type = lib.types.path; };
        subdir = lib.mkOption {
          type = lib.types.str;
          default = "skills";
        };
      };
    }
  );
in
{
  options.agents = {
    enable = lib.mkEnableOption "project-local agent skills and MCP";

    skills = lib.mkOption {
      type = lib.types.attrsOf skillEntryType;
      default = { };
      description = ''
        Skill packs and standalone skills. Same type as
        {option}`programs.agents.skills`.
      '';
    };

    mcp.servers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "MCP servers written to project config files.";
    };

    claudeSkills = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Also install skills under {file}`.claude/skills`.
        {file}`.agents/skills` is always written when skills are set.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    enterShell = agentsLib.mkProjectHook {
      inherit pkgs;
      inherit (cfg) skills;
      mcpServers = cfg.mcp.servers;
      inherit (cfg) claudeSkills;
    };
  };
}

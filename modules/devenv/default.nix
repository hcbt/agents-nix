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
    skills = lib.mkOption {
      type = lib.types.attrsOf skillEntryType;
      default = { };
      description = ''
        Skill packs and standalone skills. Same type as
        {option}`agents.skills` on the Home Manager module.
      '';
    };

    mcp.enable = lib.mkEnableOption "project-local MCP config files";

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

  config.enterShell = lib.mkIf (cfg.mcp.enable || cfg.skills != { }) (
    agentsLib.mkProjectHook {
      inherit pkgs;
      inherit (cfg) skills;
      mcpServers = cfg.mcp.servers;
      mcpEnable = cfg.mcp.enable;
      inherit (cfg) claudeSkills;
    }
  );
}

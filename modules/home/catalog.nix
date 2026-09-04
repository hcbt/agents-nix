{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.agents;
  agentsLib = import ../../lib { inherit lib; };

  skillEntryType = lib.types.either lib.types.path (
    lib.types.submodule {
      options = {
        path = lib.mkOption {
          type = lib.types.path;
          description = "Path to a pack root or a standalone skill directory.";
        };
        subdir = lib.mkOption {
          type = lib.types.str;
          default = "skills";
          description = ''
            Subdirectory of a pack to scan for {file}`SKILL.md`.
            Ignored for standalone skills.
          '';
        };
      };
    }
  );

  bundled = agentsLib.bundle {
    inherit pkgs;
    skills = cfg.skills;
  };

  inheritInstructions = agentCfg: agentCfg.enableContextIntegration && cfg.instructions != null;

  inheritSkills = agentCfg: agentCfg.enableSkillsIntegration && cfg.skills != { };
in
{
  options.programs.agents = {
    enable = lib.mkEnableOption "shared agent catalogs (MCP, skills, user instructions)";

    skills = lib.mkOption {
      type = lib.types.attrsOf skillEntryType;
      default = { };
      description = ''
        Skill packs and standalone skills. A path whose root contains
        {file}`SKILL.md` is a standalone skill named by the attribute.
        Otherwise the path is a pack; {file}`SKILL.md` directories are
        discovered and named {code}`<attr>-<folder>`.
      '';
    };

    mcp.servers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        MCP servers assigned to {option}`programs.mcp.servers`.
        {option}`programs.mcp.enable` is turned on when this is non-empty.
      '';
    };

    instructions = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.lines lib.types.path);
      default = null;
      description = ''
        Shared user instructions. Each enabled agent writes this to its
        instruction file ({file}`AGENTS.md` or {file}`CLAUDE.md`).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mcp = lib.mkIf (cfg.mcp.servers != { }) {
      enable = true;
      servers = cfg.mcp.servers;
    };

    programs.grok = lib.mkIf config.programs.grok.enable (
      lib.mkMerge [
        {
          enableMcpIntegration = lib.mkDefault true;
          enableSkillsIntegration = lib.mkDefault true;
          enableContextIntegration = lib.mkDefault true;
        }
        (lib.mkIf (inheritSkills config.programs.grok) { skills = bundled; })
        (lib.mkIf (inheritInstructions config.programs.grok) {
          context = lib.mkDefault cfg.instructions;
        })
      ]
    );

    programs.muse-code = lib.mkIf config.programs.muse-code.enable (
      lib.mkMerge [
        {
          enableMcpIntegration = lib.mkDefault true;
          enableSkillsIntegration = lib.mkDefault true;
          enableContextIntegration = lib.mkDefault true;
        }
        (lib.mkIf (inheritSkills config.programs.muse-code) { skills = bundled; })
        (lib.mkIf (inheritInstructions config.programs.muse-code) {
          context = lib.mkDefault cfg.instructions;
        })
      ]
    );
  };
}

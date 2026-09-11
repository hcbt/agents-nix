{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.agents;
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
  options.agents = {
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

    mcp.enable = lib.mkEnableOption "shared MCP catalog assigned to programs.mcp";

    mcp.servers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        MCP servers assigned to {option}`programs.mcp.servers` when
        {option}`agents.mcp.enable` is true.
      '';
    };

    instructions = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.lines lib.types.path);
      default = null;
      description = ''
        Shared user instructions. Each enabled agent writes this to its
        instruction file ({file}`AGENTS.md` or {file}`CLAUDE.md`) when
        {option}`enableContextIntegration` is true.
      '';
    };
  };

  config = {
    programs.mcp = lib.mkIf cfg.mcp.enable {
      enable = true;
      servers = cfg.mcp.servers;
    };

    programs.grok = lib.mkIf config.programs.grok.enable (
      lib.mkMerge [
        (lib.mkIf (inheritSkills config.programs.grok) { skills = bundled; })
        (lib.mkIf (inheritInstructions config.programs.grok) {
          context = lib.mkDefault cfg.instructions;
        })
      ]
    );

    programs.muse-code = lib.mkIf config.programs.muse-code.enable (
      lib.mkMerge [
        (lib.mkIf (inheritSkills config.programs.muse-code) { skills = bundled; })
        (lib.mkIf (inheritInstructions config.programs.muse-code) {
          context = lib.mkDefault cfg.instructions;
        })
      ]
    );

    programs.omp = lib.mkIf config.programs.omp.enable (
      lib.mkMerge [
        (lib.mkIf (inheritSkills config.programs.omp) { skills = bundled; })
        (lib.mkIf (inheritInstructions config.programs.omp) {
          context = lib.mkDefault cfg.instructions;
        })
      ]
    );
  };
}

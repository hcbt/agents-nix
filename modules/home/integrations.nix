{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.agents;
  agentsLib = import ../../lib { inherit lib; };

  bundled = agentsLib.bundle {
    inherit pkgs;
    skills = cfg.skills;
  };

  inheritSkills = agentCfg: agentCfg.enable && agentCfg.enableSkillsIntegration && cfg.skills != { };

  inheritInstructions =
    agentCfg: agentCfg.enable && agentCfg.enableContextIntegration && cfg.instructions != null;

  piCfg = config.programs.pi-coding-agent;
  piSkillFiles = lib.mapAttrs' (
    id: src:
    lib.nameValuePair "${piCfg.configDir}/skills/${id}" {
      source = src;
    }
  ) bundled;
in
{
  options.programs.claude-code = {
    enableSkillsIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Inherit skills from {option}`agents.skills`.";
    };
    enableContextIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Inherit user instructions from {option}`agents.instructions`.";
    };
  };

  options.programs.codex = {
    enableSkillsIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Inherit skills from {option}`agents.skills`.";
    };
    enableContextIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Inherit user instructions from {option}`agents.instructions`.";
    };
  };

  options.programs.opencode = {
    enableSkillsIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Inherit skills from {option}`agents.skills`.";
    };
    enableContextIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Inherit user instructions from {option}`agents.instructions`.";
    };
  };

  options.programs.antigravity-cli = {
    enableSkillsIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Inherit skills from {option}`agents.skills`.";
    };
    enableContextIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Inherit user instructions from {option}`agents.instructions`.";
    };
  };

  options.programs.pi-coding-agent = {
    enableSkillsIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Inherit skills from {option}`agents.skills`.";
    };
    enableContextIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Inherit user instructions from {option}`agents.instructions`.";
    };
  };

  config = {
    programs.claude-code = lib.mkIf config.programs.claude-code.enable (
      lib.mkMerge [
        (lib.mkIf (inheritSkills config.programs.claude-code) { skills = bundled; })
        (lib.mkIf (inheritInstructions config.programs.claude-code) {
          context = lib.mkDefault cfg.instructions;
        })
      ]
    );

    programs.codex = lib.mkIf config.programs.codex.enable (
      lib.mkMerge [
        (lib.mkIf (inheritSkills config.programs.codex) { skills = bundled; })
        (lib.mkIf (inheritInstructions config.programs.codex) {
          context = lib.mkDefault cfg.instructions;
        })
      ]
    );

    programs.opencode = lib.mkIf config.programs.opencode.enable (
      lib.mkMerge [
        (lib.mkIf (inheritSkills config.programs.opencode) { skills = bundled; })
        (lib.mkIf (inheritInstructions config.programs.opencode) {
          context = lib.mkDefault cfg.instructions;
        })
      ]
    );

    programs.antigravity-cli = lib.mkIf config.programs.antigravity-cli.enable (
      lib.mkMerge [
        (lib.mkIf (inheritSkills config.programs.antigravity-cli) { skills = bundled; })
        (lib.mkIf (inheritInstructions config.programs.antigravity-cli) {
          context.AGENTS = cfg.instructions;
        })
      ]
    );

    programs.pi-coding-agent = lib.mkIf piCfg.enable (
      lib.mkIf (inheritInstructions piCfg) {
        context = lib.mkDefault cfg.instructions;
      }
    );

    home.file = lib.mkIf (piCfg.enable && inheritSkills piCfg) piSkillFiles;
  };
}

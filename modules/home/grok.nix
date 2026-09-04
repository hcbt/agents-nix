{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.grok;
  tomlFormat = pkgs.formats.toml { };

  transformedMcpServers = lib.optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable) (
    lib.mapAttrs (
      name: server:
      lib.hm.mcp.transformMcpServer {
        inherit server;
        exclude = [ "type" ];
        extraTransforms = [ (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; }) ];
      }
    ) config.programs.mcp.servers
  );

  mcpServers = lib.recursiveUpdate transformedMcpServers (cfg.settings.mcp_servers or { });

  settings =
    (removeAttrs cfg.settings [ "mcp_servers" ])
    // lib.optionalAttrs (mcpServers != { }) { mcp_servers = mcpServers; };

  skillFiles = lib.mapAttrs' (
    id: src:
    lib.nameValuePair ".grok/skills/${id}" {
      source = src;
    }
  ) cfg.skills;
in
{
  options.programs.grok = {
    enable = lib.mkEnableOption "Grok Build";

    package = lib.mkPackageOption pkgs "grok-build" {
      nullable = true;
      default = null;
    };

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Merge {option}`programs.mcp.servers` into
        {option}`programs.grok.settings.mcp_servers`.
        Settings-based servers take precedence on name clash.
      '';
    };

    enableSkillsIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Inherit skills from {option}`agents.skills`.
      '';
    };

    enableContextIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Inherit user instructions from {option}`agents.instructions`.
      '';
    };

    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Configuration written to {file}`~/.grok/config.toml`.
      '';
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Skill directories written to {file}`~/.grok/skills/<name>/`.
        Each value is a directory containing {file}`SKILL.md`.
      '';
    };

    context = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.lines lib.types.path);
      default = null;
      description = ''
        User-scope instructions written to {file}`~/.grok/AGENTS.md`.
        Null skips the file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file = lib.mkMerge [
      (lib.mkIf (settings != { }) {
        ".grok/config.toml" = {
          source = tomlFormat.generate "grok-config.toml" settings;
          force = true;
        };
      })
      (lib.mkIf (cfg.context != null) (
        if lib.hm.strings.isPathLike cfg.context then
          {
            ".grok/AGENTS.md" = {
              source = cfg.context;
              force = true;
            };
          }
        else
          {
            ".grok/AGENTS.md" = {
              text = cfg.context;
              force = true;
            };
          }
      ))
      skillFiles
    ];
  };
}

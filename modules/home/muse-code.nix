{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.muse-code;
  jsonFormat = pkgs.formats.json { };

  toMuseServer =
    name: server:
    let
      wrapped = lib.hm.mcp.transformMcpServer {
        inherit server;
        exclude = [
          "type"
          "enabled"
        ];
        extraTransforms = [ (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; }) ];
      };
    in
    if wrapped ? url then
      {
        transport = "streamable_http";
        url = wrapped.url;
        enabled = true;
        mode = "required";
      }
      // lib.optionalAttrs (wrapped ? headers) { inherit (wrapped) headers; }
    else
      {
        transport = "stdio";
        command = "${wrapped.command}";
        enabled = true;
        mode = "required";
      }
      // lib.optionalAttrs (wrapped ? args) { inherit (wrapped) args; }
      // lib.optionalAttrs (wrapped ? env) { inherit (wrapped) env; };

  transformedMcpServers = lib.optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable) (
    lib.mapAttrs toMuseServer config.programs.mcp.servers
  );

  mcpServers = lib.recursiveUpdate transformedMcpServers (cfg.settings.mcpServers or { });

  settings =
    (removeAttrs cfg.settings [
      "mcpServers"
      "schemaVersion"
    ])
    // lib.optionalAttrs (cfg.settings ? schemaVersion) { schema_version = cfg.settings.schemaVersion; }
    // lib.optionalAttrs (mcpServers != { }) { mcp_servers = mcpServers; };

  skillFiles = lib.mapAttrs' (
    id: src:
    lib.nameValuePair ".config/muse/skills/${id}" {
      source = src;
    }
  ) cfg.skills;
in
{
  options.programs.muse-code = {
    enable = lib.mkEnableOption "Muse Code";

    package = lib.mkPackageOption pkgs "muse-code" {
      nullable = true;
      default = null;
    };

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Merge {option}`programs.mcp.servers` into
        {option}`programs.muse-code.settings.mcpServers`.
        Settings-based servers take precedence on name clash.
        Written as {code}`mcp_servers` in {file}`settings.json`.
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
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Configuration written to {file}`~/.config/muse/settings.json`.
        Must include {option}`schemaVersion` (use 1) or Muse refuses to start.
      '';
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Skill directories written to {file}`~/.config/muse/skills/<name>/`.
        Each value is a directory containing {file}`SKILL.md`.
        Each skill is a directory symlink so {file}`SKILL.md` stays a regular file.
      '';
    };

    context = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.lines lib.types.path);
      default = null;
      description = ''
        User-scope instructions written to {file}`~/.config/muse/AGENTS.md`.
        Null skips the file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = settings == { } || settings ? schema_version;
        message = "programs.muse-code.settings must set schemaVersion (use 1)";
      }
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file = lib.mkMerge [
      (lib.mkIf (settings != { }) {
        ".config/muse/settings.json" = {
          source = jsonFormat.generate "muse-settings.json" settings;
          force = true;
        };
      })
      (lib.mkIf (cfg.context != null) (
        if lib.hm.strings.isPathLike cfg.context then
          {
            ".config/muse/AGENTS.md" = {
              source = cfg.context;
              force = true;
            };
          }
        else
          {
            ".config/muse/AGENTS.md" = {
              text = cfg.context;
              force = true;
            };
          }
      ))
      skillFiles
    ];
  };
}

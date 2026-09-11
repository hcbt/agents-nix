{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.omp;
  yamlFormat = pkgs.formats.yaml { };
  jsonFormat = pkgs.formats.json { };

  transformedMcpServers = lib.optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable) (
    lib.mapAttrs (
      name: server:
      lib.hm.mcp.transformMcpServer {
        inherit server;
        extraTransforms = [ (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; }) ];
      }
    ) config.programs.mcp.servers
  );

  writeMcp = transformedMcpServers != { };
  writeSettings = cfg.settings != { };

  skillFiles = lib.mapAttrs' (
    id: src:
    lib.nameValuePair ".omp/agent/skills/${id}" {
      source = src;
    }
  ) cfg.skills;
in
{
  options.programs.omp = {
    enable = lib.mkEnableOption "OMP";

    package = lib.mkPackageOption pkgs "omp" {
      nullable = true;
      default = null;
    };

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Write {option}`programs.mcp.servers` to
        {file}`~/.omp/agent/mcp.json`.
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
      inherit (yamlFormat) type;
      default = { };
      description = ''
        Configuration copied to {file}`~/.omp/agent/config.yml` as a
        writable regular file. Keys stay camelCase.
      '';
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Skill directories written to {file}`~/.omp/agent/skills/<name>/`.
        Each value is a directory containing {file}`SKILL.md`.
      '';
    };

    context = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.lines lib.types.path);
      default = null;
      description = ''
        User-scope instructions written to {file}`~/.omp/agent/AGENTS.md`.
        Null skips the file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file = lib.mkMerge [
      (lib.mkIf (cfg.context != null) (
        if lib.hm.strings.isPathLike cfg.context then
          {
            ".omp/agent/AGENTS.md" = {
              source = cfg.context;
              force = true;
            };
          }
        else
          {
            ".omp/agent/AGENTS.md" = {
              text = cfg.context;
              force = true;
            };
          }
      ))
      skillFiles
    ];

    home.activation = lib.mkMerge [
      (lib.mkIf writeSettings {
        ompConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "$HOME/.omp/agent"
          run install -m 600 ${yamlFormat.generate "omp-config.yml" cfg.settings} "$HOME/.omp/agent/config.yml"
        '';
      })
      (lib.mkIf writeMcp {
        ompMcp = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run mkdir -p "$HOME/.omp/agent"
          run install -m 600 ${
            jsonFormat.generate "omp-mcp.json" {
              mcpServers = transformedMcpServers;
            }
          } "$HOME/.omp/agent/mcp.json"
        '';
      })
    ];
  };
}

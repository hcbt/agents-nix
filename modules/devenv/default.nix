{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.agents;
  agentsLib = import ../../lib { inherit lib; };

  v1Agents = [
    "grok"
    "muse-code"
    "claude-code"
    "codex"
    "opencode"
    "antigravity-cli"
    "pi-coding-agent"
  ];

  mcpShared = [
    "claude-code"
    "pi-coding-agent"
    "grok"
    "muse-code"
  ];

  skillShared = [
    "grok"
    "muse-code"
    "codex"
    "opencode"
    "antigravity-cli"
    "pi-coding-agent"
  ];

  anyFlag = flag: names: lib.any (name: cfg.${name}.${flag}) names;

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

  agentOptions = lib.listToAttrs (
    map (name: {
      inherit name;
      value = {
        enableMcpIntegration = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Write this Agent's project MCP dest from {option}`agents.mcp.servers`.
          '';
        };
        enableSkillsIntegration = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Write this Agent's project skill dest from {option}`agents.skills`.
          '';
        };
      };
    }) v1Agents
  );

  writeMcp = cfg.mcp.servers != { } && anyFlag "enableMcpIntegration" v1Agents;
  writeSkills = cfg.skills != { } && anyFlag "enableSkillsIntegration" v1Agents;

  mcpDests =
    lib.optionals (anyFlag "enableMcpIntegration" mcpShared) [ ".mcp.json" ]
    ++ lib.optionals (anyFlag "enableMcpIntegration" [ "antigravity-cli" ]) [
      ".agents/mcp_config.json"
    ]
    ++ lib.optionals (anyFlag "enableMcpIntegration" [ "codex" ]) [ ".codex/config.toml" ]
    ++ lib.optionals (anyFlag "enableMcpIntegration" [ "opencode" ]) [ "opencode.json" ];
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

    mcp.servers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "MCP servers written to project dests of opted-in Agents.";
    };
  }
  // agentOptions;

  config.enterShell = lib.mkIf (writeMcp || writeSkills) (
    agentsLib.mkProjectHook {
      inherit pkgs;
      inherit (cfg) skills;
      mcpServers = cfg.mcp.servers;
      mcpDests = if writeMcp then mcpDests else [ ];
      agentsSkills = writeSkills && anyFlag "enableSkillsIntegration" skillShared;
      claudeSkills = writeSkills && cfg.claude-code.enableSkillsIntegration;
    }
  );
}

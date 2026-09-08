{
  pkgs,
  catalog ? ../modules/home/catalog.nix,
  integrations ? ../modules/home/integrations.nix,
}:
let
  inherit (pkgs) lib;

  testLib = lib // {
    hm.dag = {
      entryBefore = before: data: {
        inherit before data;
        after = [ ];
      };
      entryAfter = after: data: {
        inherit after data;
        before = [ ];
      };
    };
  };

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

  integrationStub =
    { config, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
      codexCfg = config.programs.codex;
      codexUsesToml =
        codexCfg.package == null || lib.versionAtLeast (lib.getVersion codexCfg.package) "0.2.0";
      codexConfigFile =
        if config.home.preferXdgDirectories && codexUsesToml then
          "/.config/codex/config.toml"
        else if codexUsesToml then
          ".codex/config.toml"
        else
          ".codex/config.yaml";
      inheritedMcp = lib.optionalAttrs (codexCfg.enableMcpIntegration && config.programs.mcp.enable) {
        mcp_servers = config.programs.mcp.servers;
      };
      codexSettings = codexCfg.settings // inheritedMcp;
      commonAgentOptions = {
        enable = lib.mkEnableOption "test Agent";
        enableMcpIntegration = lib.mkOption {
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
    in
    {
      options = {
        warnings = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        home = {
          homeDirectory = lib.mkOption {
            type = lib.types.str;
            default = "/home/test";
          };
          preferXdgDirectories = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
          file = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = true;
                  };
                  source = lib.mkOption {
                    type = lib.types.nullOr lib.types.path;
                    default = null;
                  };
                };
              }
            );
            default = { };
          };
          activation = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
        };
        xdg = {
          configHome = lib.mkOption {
            type = lib.types.str;
            default = "/home/test/.config";
          };
          stateHome = lib.mkOption {
            type = lib.types.str;
            default = "/home/test/.local/state";
          };
        };
        programs = {
          claude-code = commonAgentOptions;
          codex = commonAgentOptions // {
            package = lib.mkOption {
              type = lib.types.nullOr lib.types.package;
              default = null;
            };
            settings = lib.mkOption {
              type = lib.types.attrs;
              default = { };
            };
          };
          opencode = commonAgentOptions;
          antigravity-cli = commonAgentOptions // {
            context = lib.mkOption {
              type = lib.types.attrs;
              default = { };
            };
          };
          pi-coding-agent = commonAgentOptions // {
            configDir = lib.mkOption {
              type = lib.types.str;
              default = ".pi";
            };
          };
        };
      };

      config.home.file."${codexConfigFile}".source = lib.mkIf (codexCfg.enable && codexSettings != { }) (
        tomlFormat.generate "test-codex-config" codexSettings
      );
    };

  integrationEvalWithPkgs =
    evalPkgs: extra:
    lib.evalModules {
      specialArgs = {
        pkgs = evalPkgs;
        lib = testLib;
      };
      modules = [
        catalog
        stub
        integrationStub
        integrations
      ]
      ++ extra;
    };
  integrationEval = integrationEvalWithPkgs pkgs;

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

  codexMutable = integrationEval [
    {
      programs.codex = {
        enable = true;
        enableMcpIntegration = true;
        settings.model = "old";
      };
      agents.mcp = {
        enable = true;
        servers.old.command = "old-command";
      };
    }
  ];

  codexImmutable = integrationEval [
    {
      programs.codex = {
        enable = true;
        enableMcpIntegration = true;
        mutableUserSettings = false;
      };
      agents.mcp = {
        enable = true;
        servers.old.command = "old-command";
      };
    }
  ];

  codexEmpty = integrationEval [
    { programs.codex.enable = true; }
  ];

  codexXdg = integrationEval [
    {
      home = {
        homeDirectory = "/home/test";
        preferXdgDirectories = true;
      };
      xdg = {
        configHome = "/home/test/.config";
        stateHome = "/home/test/.local/state";
      };
      programs.codex = {
        enable = true;
        settings.model = "test";
      };
    }
  ];

  oldCodex = pkgs.runCommand "codex-0.1.0" { } "mkdir -p $out";
  codexLegacy = integrationEval [
    {
      programs.codex = {
        enable = true;
        package = oldCodex;
        settings.model = "legacy";
      };
    }
  ];

  behaviorRoot = builtins.placeholder "out";
  codexBehaviorV1 = integrationEval [
    {
      home.homeDirectory = behaviorRoot;
      xdg.stateHome = "${behaviorRoot}/.local/state";
      programs.codex = {
        enable = true;
        enableMcpIntegration = true;
        settings = {
          model = "old";
          tui.theme = "dark";
        };
      };
      agents.mcp = {
        enable = true;
        servers.old.command = "old-command";
      };
    }
  ];
  codexBehaviorV2 = integrationEval [
    {
      home.homeDirectory = behaviorRoot;
      xdg.stateHome = "${behaviorRoot}/.local/state";
      programs.codex = {
        enable = true;
        enableMcpIntegration = true;
        settings = {
          model = "new";
          tui.theme = "light";
        };
      };
      agents.mcp = {
        enable = true;
        servers.new.command = "new-command";
      };
    }
  ];
  concurrentYq = pkgs.writeShellScriptBin "yq" ''
    ${lib.getExe pkgs.yq-go} "$@"
    status=$?
    if [[ "$1" == ea && -n "''${AGENTS_NIX_TEST_TARGET:-}" && ! -e "$AGENTS_NIX_TEST_SENTINEL" ]]; then
      temporary="$AGENTS_NIX_TEST_TARGET.concurrent"
      cp "$AGENTS_NIX_TEST_TARGET" "$temporary"
      ${lib.getExe pkgs.yq-go} -i -p toml -o toml \
        '.projects."/concurrent".trust_level = "trusted"' "$temporary"
      mv "$temporary" "$AGENTS_NIX_TEST_TARGET"
      touch "$AGENTS_NIX_TEST_SENTINEL"
    fi
    exit "$status"
  '';
  concurrentPkgs = pkgs // {
    yq-go = concurrentYq;
  };
  codexBehaviorConcurrent = integrationEvalWithPkgs concurrentPkgs [
    {
      home.homeDirectory = behaviorRoot;
      xdg.stateHome = "${behaviorRoot}/.local/state";
      programs.codex = {
        enable = true;
        enableMcpIntegration = true;
        settings = {
          model = "new";
          tui.theme = "light";
        };
      };
      agents.mcp = {
        enable = true;
        servers.new.command = "new-command";
      };
    }
  ];
  codexBehaviorV1Source = codexBehaviorV1.config.home.file.".codex/config.toml".source;
  captureV1 = codexBehaviorV1.config.home.activation.captureCodexMutableSettings.data;
  mergeV1 = codexBehaviorV1.config.home.activation.mergeCodexMutableSettings.data;
  captureV2 = codexBehaviorV2.config.home.activation.captureCodexMutableSettings.data;
  mergeV2 = codexBehaviorV2.config.home.activation.mergeCodexMutableSettings.data;
  captureConcurrent = codexBehaviorConcurrent.config.home.activation.captureCodexMutableSettings.data;
  mergeConcurrent = codexBehaviorConcurrent.config.home.activation.mergeCodexMutableSettings.data;
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
assert lib.assertMsg codexMutable.config.programs.codex.mutableUserSettings
  "programs.codex.mutableUserSettings must default to true";
assert lib.assertMsg (
  !codexMutable.config.home.file.".codex/config.toml".enable
) "mutable Codex settings must disable Home Manager's generated symlink";
assert lib.assertMsg (
  codexMutable.config.home.activation ? captureCodexMutableSettings
) "mutable Codex settings must capture the previous generated settings before linkGeneration";
assert lib.assertMsg (
  codexMutable.config.home.activation ? mergeCodexMutableSettings
) "mutable Codex settings must merge after linkGeneration";
assert lib.assertMsg codexImmutable.config.home.file.".codex/config.toml".enable
  "mutableUserSettings = false must retain Home Manager's generated symlink";
assert lib.assertMsg (
  !codexImmutable.config.home.activation ? mergeCodexMutableSettings
) "mutableUserSettings = false must not install a mutable settings activation";
assert lib.assertMsg codexEmpty.config.home.file.".codex/config.toml".enable
  "empty Codex settings must not create or disable a generated settings file";
assert lib.assertMsg (
  !codexXdg.config.home.file."/.config/codex/config.toml".enable
) "mutable Codex settings must follow Home Manager's XDG config path";
assert lib.assertMsg (
  !codexLegacy.config.home.activation ? mergeCodexMutableSettings
) "legacy YAML Codex settings must remain immutable";
assert lib.assertMsg (
  codexLegacy.config.warnings != [ ]
) "legacy YAML Codex settings must warn that mutableUserSettings does not apply";
pkgs.runCommand "eval-hm-ok"
  {
    nativeBuildInputs = [
      pkgs.coreutils
      pkgs.yq-go
    ];
  }
  ''
    set -euo pipefail
    config="$out/.codex/config.toml"
    state="$out/.local/state/agents-nix/codex"

    # Migrate the old Home Manager store symlink to a writable file.
    mkdir -p "$out/.codex"
    ln -s ${codexBehaviorV1Source} "$config"
    ${captureV1}
    ${mergeV1}
    test -f "$config"
    test ! -L "$config"
    test -f "$state/managed-settings.toml"
    test "$(stat -c %a "$state")" = 700
    test "$(stat -c %a "$config")" = 600
    test "$(stat -c %a "$state/managed-settings.toml")" = 600
    test "$(yq -r '.model' "$config")" = old
    test "$(yq -r '.mcp_servers.old.command' "$config")" = old-command

    # Preserve Runtime state while replacing and removing Declarative settings.
    yq -i -p toml -o toml \
      '.projects."/repo".trust_level = "trusted" |
       .tui.model_availability_nux.seen_count = 2 |
       .projects."/repo".trust_level line_comment = "runtime comment"' \
      "$config"
    ${captureV2}
    ${mergeV2}
    test "$(yq -r '.model' "$config")" = new
    test "$(yq -r '.tui.theme' "$config")" = light
    test "$(yq -r '.tui.model_availability_nux.seen_count' "$config")" = 2
    test "$(yq -r '.projects."/repo".trust_level' "$config")" = trusted
    test "$(yq -r '.mcp_servers.new.command' "$config")" = new-command
    test "$(yq -r '.mcp_servers.old' "$config")" = null
    grep -q '# runtime comment' "$config"
    test -f "$state/config.toml.previous"

    # A Home Manager rollback restores Declarative settings but keeps Runtime state.
    ${captureV1}
    ${mergeV1}
    test "$(yq -r '.model' "$config")" = old
    test "$(yq -r '.tui.theme' "$config")" = dark
    test "$(yq -r '.tui.model_availability_nux.seen_count' "$config")" = 2
    test "$(yq -r '.projects."/repo".trust_level' "$config")" = trusted
    test "$(yq -r '.mcp_servers.old.command' "$config")" = old-command
    test "$(yq -r '.mcp_servers.new' "$config")" = null

    # A semantic no-op leaves the live file byte-for-byte unchanged.
    cp "$config" "$out/noop-before.toml"
    ${captureV1}
    ${mergeV1}
    cmp "$out/noop-before.toml" "$config"

    # A concurrent Codex write causes a retry and is included in the merge.
    export AGENTS_NIX_TEST_TARGET="$config"
    export AGENTS_NIX_TEST_SENTINEL="$out/concurrent-write-observed"
    ${captureConcurrent}
    ${mergeConcurrent}
    unset AGENTS_NIX_TEST_TARGET AGENTS_NIX_TEST_SENTINEL
    test -f "$out/concurrent-write-observed"
    test "$(yq -r '.model' "$config")" = new
    test "$(yq -r '.projects."/concurrent".trust_level' "$config")" = trusted

    # On first adoption of a regular file, MCP is declarative-only while other
    # Runtime state is retained.
    rm -f \
      "$config" \
      "$state/managed-settings.toml" \
      "$state/pending-managed-settings.toml" \
      "$state/config.toml.previous"
    printf '%s\n' \
      '[projects."/adopted"]' \
      'trust_level = "trusted"' \
      '[mcp_servers.runtime]' \
      'command = "runtime-command"' > "$config"
    ${captureV1}
    ${mergeV1}
    test "$(yq -r '.projects."/adopted".trust_level' "$config")" = trusted
    test "$(yq -r '.mcp_servers.old.command' "$config")" = old-command
    test "$(yq -r '.mcp_servers.runtime' "$config")" = null

    # Malformed TOML fails without changing either the live file or snapshot.
    cp "$state/managed-settings.toml" "$out/snapshot-before.toml"
    printf '%s\n' '[broken' > "$config"
    cp "$config" "$out/malformed-before.toml"
    if (${mergeV1}); then
      echo "malformed Codex settings unexpectedly succeeded" >&2
      exit 1
    fi
    cmp "$out/malformed-before.toml" "$config"
    cmp "$out/snapshot-before.toml" "$state/managed-settings.toml"

    touch "$out/passed"
  ''

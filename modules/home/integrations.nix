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

  codexCfg = config.programs.codex;
  codexUsesToml =
    codexCfg.package == null || lib.versionAtLeast (lib.getVersion codexCfg.package) "0.2.0";
  codexUsesXdg = config.home.preferXdgDirectories && codexUsesToml;
  codexXdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
  codexConfigDir = if codexUsesXdg then "${codexXdgConfigHome}/codex" else ".codex";
  codexConfigFile = "${codexConfigDir}/config.toml";
  codexConfigSource = lib.attrByPath [ codexConfigFile "source" ] null config.home.file;
  codexGeneratesSettings =
    (codexCfg.settings != null && codexCfg.settings != { })
    || (
      codexCfg.enableMcpIntegration && config.programs.mcp.enable && config.programs.mcp.servers != { }
    )
    || (codexCfg.plugins or [ ]) != [ ]
    || (codexCfg.marketplaces or { }) != { };
  codexMutableSettingsEnabled =
    codexCfg.enable && codexCfg.mutableUserSettings && codexUsesToml && codexGeneratesSettings;
  codexMutableSettings = codexMutableSettingsEnabled && codexConfigSource != null;
  codexConfigPath = "${config.home.homeDirectory}/${codexConfigFile}";
  codexStateDir = "${config.xdg.stateHome}/agents-nix/codex";
  codexOwnershipSnapshot = "${codexStateDir}/managed-settings.toml";
  codexPendingSnapshot = "${codexStateDir}/pending-managed-settings.toml";
  codexRecoveryCopy = "${codexStateDir}/config.toml.previous";
  codexReplaceMcpOnAdoption = codexCfg.enableMcpIntegration && config.programs.mcp.enable;

  codexMutableSettingsCommand = pkgs.writeShellApplication {
    name = "agents-nix-codex-mutable-settings";
    excludeShellChecks = [ "SC2016" ];
    runtimeInputs = [
      pkgs.coreutils
      pkgs.yq-go
    ];
    text = ''
      set -euo pipefail
      umask 077

      action="$1"
      target="$2"
      static_settings="$3"
      ownership_snapshot="$4"
      pending_snapshot="$5"
      recovery_copy="$6"
      replace_mcp_on_adoption="$7"
      state_dir="''${ownership_snapshot%/*}"

      mkdir -p "$state_dir"
      chmod 0700 "$state_dir"

      if [[ "$action" == capture ]]; then
        rm -f "$pending_snapshot"
        if [[ -L "$target" ]]; then
          link_target="$(readlink "$target")"
          if [[ "$link_target" == /nix/store/* ]]; then
            cp -L "$target" "$pending_snapshot"
            chmod 0600 "$pending_snapshot"
          fi
        fi
        exit 0
      fi

      if [[ "$action" != merge ]]; then
        echo "unknown action: $action" >&2
        exit 2
      fi

      if ! yq -p toml -o json '.' "$static_settings" >/dev/null; then
        echo "generated Codex settings are not valid TOML: $static_settings" >&2
        exit 1
      fi

      install_snapshot() {
        snapshot_tmp="$(mktemp "$state_dir/.managed-settings.XXXXXX")"
        cp "$static_settings" "$snapshot_tmp"
        chmod 0600 "$snapshot_tmp"
        mv -f "$snapshot_tmp" "$ownership_snapshot"
        rm -f "$pending_snapshot"
      }

      target_dir="''${target%/*}"
      mkdir -p "$target_dir"

      for attempt in 1 2 3; do
        work_dir="$(mktemp -d "$state_dir/merge.XXXXXX")"
        input="$work_dir/input.toml"
        old_managed="$work_dir/old-managed.toml"
        candidate="$work_dir/candidate.toml"
        input_existed=false

        if [[ -e "$target" || -L "$target" ]]; then
          cp -L "$target" "$input"
          input_existed=true
        else
          printf '\n' > "$input"
        fi

        if ! yq -p toml -o json '.' "$input" >/dev/null; then
          echo "existing Codex settings are not valid TOML: $target" >&2
          rm -rf "$work_dir"
          exit 1
        fi

        if [[ -f "$pending_snapshot" ]]; then
          cp "$pending_snapshot" "$old_managed"
        elif [[ -f "$ownership_snapshot" ]]; then
          cp "$ownership_snapshot" "$old_managed"
        elif [[ "$replace_mcp_on_adoption" == true ]]; then
          yq -p toml -o toml '(.mcp_servers // {}) as $mcp | {"mcp_servers": $mcp}' \
            "$input" > "$old_managed"
        else
          printf '\n' > "$old_managed"
        fi

        if ! yq ea -p toml -o toml \
          'select(fi == 0) as $dynamic |
           select(fi == 1) as $old |
           select(fi == 2) as $new |
           ($old | [.. |
             select(((tag != "!!map") or (length == 0)) and ((path | length) > 0)) |
             path]) as $managed |
           (($dynamic | delpaths($managed)) * $new)' \
          "$input" "$old_managed" "$static_settings" > "$candidate"; then
          echo "failed to merge Codex settings: $target" >&2
          rm -rf "$work_dir"
          exit 1
        fi

        if ! yq -p toml -o json '.' "$candidate" >/dev/null; then
          echo "merged Codex settings are not valid TOML: $target" >&2
          rm -rf "$work_dir"
          exit 1
        fi

        if [[ ! -L "$target" ]] && \
          [[ "$(yq ea -p toml -o json 'select(fi == 0) == select(fi == 1)' \
            "$input" "$candidate")" == true ]]; then
          install_snapshot
          rm -rf "$work_dir"
          exit 0
        fi

        unchanged=false
        if [[ "$input_existed" == true ]]; then
          if [[ ( -e "$target" || -L "$target" ) ]] && cmp -s "$input" "$target"; then
            unchanged=true
          fi
        elif [[ ! -e "$target" && ! -L "$target" ]]; then
          unchanged=true
        fi

        if [[ "$unchanged" != true ]]; then
          rm -rf "$work_dir"
          if [[ "$attempt" == 3 ]]; then
            echo "Codex settings changed repeatedly during Home Manager activation; stop Codex and retry" >&2
            exit 1
          fi
          continue
        fi

        if [[ "$input_existed" == true ]]; then
          recovery_tmp="$(mktemp "$state_dir/.config.toml.previous.XXXXXX")"
          cp "$input" "$recovery_tmp"
          chmod 0600 "$recovery_tmp"
        else
          recovery_tmp=""
        fi

        target_tmp="$(mktemp "$target_dir/.config.toml.agents-nix.XXXXXX")"
        cp "$candidate" "$target_tmp"
        chmod 0600 "$target_tmp"

        unchanged=false
        if [[ "$input_existed" == true ]]; then
          if [[ ( -e "$target" || -L "$target" ) ]] && cmp -s "$input" "$target"; then
            unchanged=true
          fi
        elif [[ ! -e "$target" && ! -L "$target" ]]; then
          unchanged=true
        fi

        if [[ "$unchanged" != true ]]; then
          rm -f "$target_tmp"
          [[ -z "$recovery_tmp" ]] || rm -f "$recovery_tmp"
          rm -rf "$work_dir"
          if [[ "$attempt" == 3 ]]; then
            echo "Codex settings changed repeatedly during Home Manager activation; stop Codex and retry" >&2
            exit 1
          fi
          continue
        fi

        if [[ -n "$recovery_tmp" ]]; then
          mv -f "$recovery_tmp" "$recovery_copy"
        fi
        mv -f "$target_tmp" "$target"
        install_snapshot
        rm -rf "$work_dir"
        exit 0
      done
    '';
  };

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
    mutableUserSettings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether Codex can update its user settings file. When enabled,
        Home Manager's generated settings are merged into a writable file while
        preserving Codex runtime state. This is a compatibility shim for Home
        Manager issue #9397.
      '';
    };
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
    warnings = lib.optional (codexCfg.enable && codexCfg.mutableUserSettings && !codexUsesToml) ''
      `programs.codex.mutableUserSettings` applies only to Codex 0.2.0 or later;
      the legacy YAML settings file remains immutable.
    '';

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

    home.file = lib.mkMerge [
      (lib.mkIf (piCfg.enable && inheritSkills piCfg) piSkillFiles)
      (lib.mkIf codexMutableSettingsEnabled {
        "${codexConfigFile}".enable = lib.mkForce false;
      })
    ];

    home.activation = lib.mkIf codexMutableSettings {
      captureCodexMutableSettings = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
        if [[ -z "''${DRY_RUN_CMD:-}" ]]; then
          ${lib.getExe codexMutableSettingsCommand} \
            capture \
            ${lib.escapeShellArg codexConfigPath} \
            ${lib.escapeShellArg codexConfigSource} \
            ${lib.escapeShellArg codexOwnershipSnapshot} \
            ${lib.escapeShellArg codexPendingSnapshot} \
            ${lib.escapeShellArg codexRecoveryCopy} \
            ${lib.boolToString codexReplaceMcpOnAdoption}
        fi
      '';
      mergeCodexMutableSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        if [[ -z "''${DRY_RUN_CMD:-}" ]]; then
          ${lib.getExe codexMutableSettingsCommand} \
            merge \
            ${lib.escapeShellArg codexConfigPath} \
            ${lib.escapeShellArg codexConfigSource} \
            ${lib.escapeShellArg codexOwnershipSnapshot} \
            ${lib.escapeShellArg codexPendingSnapshot} \
            ${lib.escapeShellArg codexRecoveryCopy} \
            ${lib.boolToString codexReplaceMcpOnAdoption}
        fi
      '';
    };
  };
}

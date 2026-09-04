{ lib }:
let
  inherit (import ./discover.nix { inherit lib; }) discover;
  inherit (import ./bundle.nix { inherit lib; }) bundle;
  inherit (import ./mcp-files.nix { inherit lib; })
    mcpJson
    codexToml
    opencodeJson
    ;

  markerName = ".agents-nix-managed.json";

  skillsHook =
    {
      bundleDrv,
      agentsSkills,
      claudeSkills,
    }:
    lib.optionalString (bundleDrv != null) ''
      install_skills_dir() {
        local dest="$1"
        if [ -e "$dest" ] && [ ! -f "$dest/${markerName}" ]; then
          echo "agents-nix: refusing to replace unmarked $dest" >&2
          exit 1
        fi
        mkdir -p "$dest"
        find "$dest" -mindepth 1 -maxdepth 1 ! -name '${markerName}' -exec rm -rf {} +
        for skill in ${lib.escapeShellArg (toString bundleDrv)}/*; do
          [ -e "$skill" ] || continue
          ln -s "$skill" "$dest/$(basename "$skill")"
        done
        printf '%s\n' '{"version":1,"kind":"skills"}' > "$dest/${markerName}"
      }

      ${lib.optionalString agentsSkills ''install_skills_dir "$PWD/.agents/skills"''}
      ${lib.optionalString claudeSkills ''install_skills_dir "$PWD/.claude/skills"''}
    '';

  mcpHook =
    files:
    lib.concatMapStringsSep "\n" (
      spec:
      lib.optionalString (spec.src != null) ''
        take_file() {
          local file="$1"
          mkdir -p "$(dirname "$file")"
          if [ -e "$file" ]; then
            rm -rf "$file.old"
            mv "$file" "$file.old"
          fi
        }
        take_file "$PWD/${spec.rel}"
        rm -f "$PWD/${spec.rel}"
        cp ${lib.escapeShellArg (toString spec.src)} "$PWD/${spec.rel}"
        chmod u+w "$PWD/${spec.rel}"
      ''
    ) files;
in
{
  inherit markerName;

  mkProjectHook =
    {
      pkgs,
      skills ? { },
      mcpServers ? { },
      mcpDests ? [ ],
      agentsSkills ? false,
      claudeSkills ? false,
    }:
    let
      catalog = discover skills;
      bundleAttrs = bundle { inherit pkgs skills; };
      bundleDrv =
        if catalog == { } then
          null
        else
          pkgs.runCommand "agent-skills-bundle" { } ''
            mkdir -p "$out"
            ${lib.concatMapStringsSep "\n" (
              id: "ln -s ${lib.escapeShellArg (toString bundleAttrs.${id})} \"$out/${id}\""
            ) (lib.attrNames bundleAttrs)}
          '';
      jsonFormat = pkgs.formats.json { };
      tomlFormat = pkgs.formats.toml { };
      mcpSrc =
        rel:
        if rel == ".mcp.json" || rel == ".agents/mcp_config.json" then
          jsonFormat.generate "mcp.json" (mcpJson mcpServers)
        else if rel == ".codex/config.toml" then
          tomlFormat.generate "codex-mcp.toml" (codexToml mcpServers)
        else if rel == "opencode.json" then
          jsonFormat.generate "opencode-mcp.json" (opencodeJson mcpServers)
        else
          throw "agents-nix: unknown MCP dest ${rel}";
      mcpFiles = map (rel: {
        inherit rel;
        src = mcpSrc rel;
      }) mcpDests;
    in
    ''
      set -euo pipefail
      ${skillsHook {
        inherit bundleDrv agentsSkills claudeSkills;
      }}
      ${mcpHook mcpFiles}
    '';
}

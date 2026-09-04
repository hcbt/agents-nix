{
  pkgs,
  module ? ../modules/devenv,
}:
let
  inherit (pkgs) lib;

  eval =
    extra:
    lib.evalModules {
      modules = [
        { _module.args = { inherit pkgs; }; }
        {
          options.enterShell = lib.mkOption {
            type = lib.types.lines;
            default = "";
          };
        }
        module
      ]
      ++ extra;
    };

  ghidra = {
    command = "npx";
    args = [
      "-y"
      "ghidra"
    ];
  };

  base = eval [ ];
  serversOnly = eval [ { agents.mcp.servers.ghidra = ghidra; } ];
  grokFlagOnly = eval [ { agents.grok.enableMcpIntegration = true; } ];
  grokMcp = eval [
    {
      agents.mcp.servers.ghidra = ghidra;
      agents.grok.enableMcpIntegration = true;
    }
  ];
  claudeAndGrokMcp = eval [
    {
      agents.mcp.servers.ghidra = ghidra;
      agents.grok.enableMcpIntegration = true;
      agents.claude-code.enableMcpIntegration = true;
    }
  ];
  museMcp = eval [
    {
      agents.mcp.servers.ghidra = ghidra;
      agents.muse-code.enableMcpIntegration = true;
    }
  ];
  antigravityMcp = eval [
    {
      agents.mcp.servers.ghidra = ghidra;
      agents.antigravity-cli.enableMcpIntegration = true;
    }
  ];
  opencodeMcp = eval [
    {
      agents.mcp.servers.ghidra = ghidra;
      agents.opencode.enableMcpIntegration = true;
    }
  ];
  codexMcp = eval [
    {
      agents.mcp.servers.ghidra = ghidra;
      agents.codex.enableMcpIntegration = true;
    }
  ];
  skillsOnly = eval [ { agents.skills.review = ./fixtures/standalone; } ];
  grokSkills = eval [
    {
      agents.skills.review = ./fixtures/standalone;
      agents.grok.enableSkillsIntegration = true;
    }
  ];
  claudeSkills = eval [
    {
      agents.skills.review = ./fixtures/standalone;
      agents.claude-code.enableSkillsIntegration = true;
    }
  ];
  grokAndClaudeSkills = eval [
    {
      agents.skills.review = ./fixtures/standalone;
      agents.grok.enableSkillsIntegration = true;
      agents.claude-code.enableSkillsIntegration = true;
    }
  ];

  v1Agents = [
    "grok"
    "muse-code"
    "claude-code"
    "codex"
    "opencode"
    "antigravity-cli"
    "pi-coding-agent"
  ];
in
assert lib.assertMsg (!(base.options.agents ? enable)) "agents.enable must not exist";
assert lib.assertMsg (!(base.options.agents.mcp ? enable)) "agents.mcp.enable must not exist";
assert lib.assertMsg (!(base.options.agents ? claudeSkills)) "agents.claudeSkills must not exist";
assert lib.assertMsg (base.options.agents.mcp ? servers) "agents.mcp.servers must exist";
assert lib.assertMsg (base.config.enterShell == "") "empty import must not write a project hook";
assert lib.assertMsg (
  serversOnly.config.enterShell == ""
) "filled servers without an Agent flag must not write MCP dests";
assert lib.assertMsg (
  grokFlagOnly.config.enterShell == ""
) "an MCP flag without servers must not write MCP dests";
assert lib.assertMsg (
  skillsOnly.config.enterShell == ""
) "a skills map without an Agent flag must not write skill dests";
assert lib.assertMsg (lib.all (
  name:
  base.options.agents.${name} ? enableMcpIntegration
  && !base.config.agents.${name}.enableMcpIntegration
  && base.options.agents.${name} ? enableSkillsIntegration
  && !base.config.agents.${name}.enableSkillsIntegration
) v1Agents) "every v1 Agent must expose both integration flags, default false";
pkgs.runCommand "eval-devenv-ok"
  {
    nativeBuildInputs = [
      pkgs.jq
      pkgs.python3
    ];
  }
  ''
    set -euo pipefail
    jq=${lib.escapeShellArg (lib.getExe pkgs.jq)}
    python=${lib.escapeShellArg (lib.getExe pkgs.python3)}

    no_breadcrumb() {
      ! find "$1" -name '*.agents-nix' | grep -q .
    }

    assert_ghidra_json() {
      "$jq" -e '.mcpServers.ghidra.command == "npx"' "$1" >/dev/null
    }

    tmp=$(mktemp -d)

    mkdir "$tmp/grok-mcp"
    (
      cd "$tmp/grok-mcp"
      ${grokMcp.config.enterShell}
      test -f .mcp.json
      test ! -e .mcp.json.old
      test ! -e .mcp.json.agents-nix
      test ! -e .grok/config.toml
      test ! -e opencode.json
      test ! -e .codex/config.toml
      test ! -e .agents/mcp_config.json
      assert_ghidra_json .mcp.json
      no_breadcrumb .
      ${grokMcp.config.enterShell}
      test -f .mcp.json.old
      test ! -e .mcp.json.agents-nix
      assert_ghidra_json .mcp.json
    )

    mkdir "$tmp/shared-mcp"
    (
      cd "$tmp/shared-mcp"
      ${claudeAndGrokMcp.config.enterShell}
      test -f .mcp.json
      test ! -e .mcp.json.claude
      test ! -e .mcp.json.grok
      test ! -e .grok/config.toml
      test ! -e opencode.json
      assert_ghidra_json .mcp.json
    )

    mkdir "$tmp/muse-mcp"
    (
      cd "$tmp/muse-mcp"
      ${museMcp.config.enterShell}
      test -f .mcp.json
      test ! -e .grok/config.toml
      assert_ghidra_json .mcp.json
    )

    mkdir "$tmp/antigravity-mcp"
    (
      cd "$tmp/antigravity-mcp"
      ${antigravityMcp.config.enterShell}
      test -f .agents/mcp_config.json
      test ! -e .mcp.json
      assert_ghidra_json .agents/mcp_config.json
    )

    mkdir "$tmp/opencode-mcp"
    (
      cd "$tmp/opencode-mcp"
      ${opencodeMcp.config.enterShell}
      test -f opencode.json
      test ! -e .mcp.json
      "$jq" -e '.mcp.ghidra.command[0] == "npx"' opencode.json >/dev/null
    )

    mkdir "$tmp/codex-mcp"
    (
      cd "$tmp/codex-mcp"
      ${codexMcp.config.enterShell}
      test -f .codex/config.toml
      test ! -e .mcp.json
      "$python" -c 'import tomllib, pathlib, sys; c=tomllib.loads(pathlib.Path(".codex/config.toml").read_text()); sys.exit(0 if c["mcp_servers"]["ghidra"]["command"]=="npx" else 1)'
    )

    mkdir "$tmp/grok-skills"
    (
      cd "$tmp/grok-skills"
      ${grokSkills.config.enterShell}
      test -d .agents/skills/review
      test -f .agents/skills/.agents-nix-managed.json
      test ! -e .claude/skills
      test ! -e .mcp.json
    )

    mkdir "$tmp/claude-skills"
    (
      cd "$tmp/claude-skills"
      ${claudeSkills.config.enterShell}
      test -d .claude/skills/review
      test ! -e .agents/skills
    )

    mkdir "$tmp/both-skills"
    (
      cd "$tmp/both-skills"
      ${grokAndClaudeSkills.config.enterShell}
      test -d .agents/skills/review
      test -d .claude/skills/review
    )

    touch "$out"
  ''

# agents-nix

Home Manager and devenv modules that declare CLI coding agents and the catalogs they share: MCP servers, skills, and user instructions.

## Home Manager

```nix
{
  imports = [ inputs.agents-nix.homeManagerModules.default ];

  agents = {
    skills.pack-a = inputs.pack-a;
    skills.my-review = ./review;
    mcp.enable = true;
    mcp.servers.context7 = {
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp" ];
    };
    instructions = ./AGENTS.md;
  };

  programs.grok.enable = true;
  programs.grok.enableMcpIntegration = true;
  programs.grok.enableSkillsIntegration = true;
  programs.grok.enableContextIntegration = true;
}
```

Catalogs live at `agents.*`. `agents.mcp.enable` assigns `programs.mcp` and does not turn on any harness integration flag. Each enabled `programs.<agent>` inherits a catalog only when that agent sets `enableMcpIntegration`, `enableSkillsIntegration`, or `enableContextIntegration`.

## devenv

```nix
{ inputs, ... }:
{
  imports = [ inputs.agents-nix.devenvModules.default ];

  agents.skills.pack-a = inputs.pack-a;
  agents.mcp.servers.context7 = {
    command = "npx";
    args = [ "-y" "@upstash/context7-mcp" ];
  };
  agents.grok.enableMcpIntegration = true;
  agents.grok.enableSkillsIntegration = true;
}
```

Filling a catalog writes nothing until an Agent’s matching integration flag is on. MCP dests: `.mcp.json` (Claude, Pi, Grok, Muse, OMP), `.agents/mcp_config.json` (Antigravity), `.codex/config.toml`, `opencode.json`. Skills dests: `.agents/skills`, and `.claude/skills` when Claude’s skills flag is on. Shared dests are one file. Unmarked skill directories are left alone. An existing MCP dest that differs is renamed to `*.old` and replaced.

## lib

`discover`, `bundle`, and `mkProjectHook` for flakes that are not using Home Manager or devenv.

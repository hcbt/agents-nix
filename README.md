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
  agents.mcp.enable = true;
  agents.mcp.servers.context7 = {
    command = "npx";
    args = [ "-y" "@upstash/context7-mcp" ];
  };
}
```

Skill dests are written when `agents.skills` is non-empty. MCP files are written when `agents.mcp.enable` is true. `agents.claudeSkills = false` skips `.claude/skills`. Unmarked skill directories are left alone. Existing MCP files are renamed to `*.old` on first takeover. Per-file stamps are named `*.agents-nix`; add those to gitignore too.

## lib

`discover`, `bundle`, and `mkProjectHook` for flakes that are not using Home Manager or devenv.

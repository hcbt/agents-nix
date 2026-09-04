# agents-nix

Home Manager and devenv modules that declare CLI coding agents and the catalogs they share: MCP servers, skills, and user instructions.

## Home Manager

```nix
{
  imports = [ inputs.agents-nix.homeManagerModules.default ];

  programs.agents = {
    enable = true;
    skills.pack-a = inputs.pack-a;
    skills.my-review = ./review;
    mcp.servers.context7 = {
      command = "npx";
      args = [ "-y" "@upstash/context7-mcp" ];
    };
    instructions = ./AGENTS.md;
  };

  programs.grok.enable = true;
}
```

`programs.agents.enable` defaults to false. Catalogs inherit onto each enabled `programs.<agent>` unless that agent sets `enableMcpIntegration`, `enableSkillsIntegration`, or `enableContextIntegration` to false.

## devenv

```nix
{ inputs, ... }:
{
  imports = [ inputs.agents-nix.devenvModules.default ];

  agents.enable = true;
  agents.skills.pack-a = inputs.pack-a;
  agents.mcp.servers.context7 = {
    command = "npx";
    args = [ "-y" "@upstash/context7-mcp" ];
  };
}
```

Project dests (gitignored): `.agents/skills`, `.claude/skills`, `.mcp.json`, plus holdout MCP files for Grok, Codex, and OpenCode. Unmarked skill directories are left alone. Existing MCP files are renamed to `*.old` on first takeover. Per-file stamps are named `*.agents-nix`; add those to gitignore too.

## lib

`discover`, `bundle`, and `mkProjectHook` for flakes that are not using Home Manager or devenv.

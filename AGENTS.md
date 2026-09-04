# agents-nix

Home Manager and devenv modules that declare CLI coding agents and the catalogs they share: MCP servers, skills, and user instructions.

Flake outputs: `homeManagerModules.default`, `devenvModules.default`, `lib`.

`CLAUDE.md` is a symlink to this file. Edit this file only.

## Use

Catalogs live at `agents.skills`, `agents.mcp`, and `agents.instructions`. An enabled `programs.<agent>` inherits a catalog only when that agent sets the matching flag: `enableMcpIntegration`, `enableSkillsIntegration`, or `enableContextIntegration`. Filling a catalog does not turn those flags on. There is no `agents.enable`.

Import and config snippets: `README.md`.

v1 Agents (ADR 0004): `grok`, `muse-code`, `claude-code`, `codex`, `opencode`, `antigravity-cli`, `pi-coding-agent`. Grok and Muse are modules in this flake. The others extend Home Manager: add options and assign `config`; leave existing options to Home Manager.

## Vocabulary and decisions

Terms: `CONTEXT.md`. How to consume the glossary and ADRs: `docs/agents/domain.md`.

Decisions: `docs/adr/`. Read the ADRs that touch the area before changing it. A later number wins when two ADRs conflict.

## Layout

- `modules/home/` — catalogs, Grok, Muse, inheritance into Home Manager agents
- `modules/devenv/` — project-local skill dests and MCP files (`enterShell`)
- `lib/` — discover, bundle, install, MCP file shapes, camelCase → snake_case
- `tests/` — eval-time asserts (`eval-hm.nix`, `eval-devenv.nix`, `eval-keys.nix`) plus fixtures

Project dests: `.agents/skills` when skills are set; `.claude/skills` unless `agents.claudeSkills = false`. Unmarked skill dests are refused. MCP files are overwritten; the previous file is `*.old`. Stamps are `*.agents-nix`.

Grok and Muse `settings` use camelCase Nix keys. Files get snake_case via `toFileKeys`.

## Develop

```
devenv shell -- nixfmt <changed.nix>
devenv shell -- nix flake check
```

A behavior change is an `assert` in the matching `tests/eval-*.nix`. A new check file is an attribute under `outputs.checks` in `flake.nix`.

| Change | Edit |
| --- | --- |
| Catalog inheritance for Grok or Muse | `modules/home/catalog.nix`, `tests/eval-hm.nix` |
| Catalog inheritance for claude-code, codex, opencode, antigravity-cli, pi-coding-agent | `modules/home/integrations.nix`, `tests/eval-hm.nix` |
| Grok or Muse module | `modules/home/grok.nix` or `muse-code.nix` |
| Project-local dests or MCP files | `lib/install.nix`, `lib/mcp-files.nix`, `tests/eval-devenv.nix` |
| Skill ids, packs, standalone entries | `lib/discover.nix`, `lib/bundle.nix` |
| Settings key conversion | `lib/file-keys.nix`, `tests/eval-keys.nix` |

## Issues

GitHub Issues. `gh` operations: `docs/agents/issue-tracker.md`. Triage labels: `docs/agents/triage-labels.md`.

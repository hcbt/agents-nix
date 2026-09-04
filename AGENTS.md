## Agent skills

### Issue tracker

Issues live in this repo's GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Develop

`CLAUDE.md` is a symlink to this file. Edit this file only.

Run commands inside devenv: `devenv shell -- <cmd>`.

### Change the flake

1. Read `CONTEXT.md`. Use those terms for any domain concept you name.
2. Read `docs/adr/` entries that touch the area. A later number wins when two ADRs conflict.
3. Add or extend an `assert` in the matching `tests/eval-*.nix` for every new behavior.
4. Change the module or lib for that behavior (branches below).
5. Format the Nix you touched: `devenv shell -- nixfmt <file>`.
6. Run `devenv shell -- nix flake check`.

The change is done when the check passes and every new behavior has an assert.

**Catalog inheritance for Grok or Muse** — `modules/home/catalog.nix`, assert in `tests/eval-hm.nix`.

**Catalog inheritance for claude-code, codex, opencode, antigravity-cli, pi-coding-agent** — `modules/home/integrations.nix`, assert in `tests/eval-hm.nix`. Where Home Manager already declares an option, assign `config` and add new options only.

**Grok or Muse module** — `modules/home/grok.nix` or `modules/home/muse-code.nix`. `settings` keys are camelCase in Nix; `toFileKeys` writes snake_case.

**Project-local dests or MCP files** — `lib/install.nix`, `lib/mcp-files.nix`, assert in `tests/eval-devenv.nix`. Unmarked skill dests are refused. MCP takeover overwrites and leaves `*.old`.

**Skill ids, packs, standalone entries** — `lib/discover.nix`, `lib/bundle.nix`.

**Settings key conversion** — `lib/file-keys.nix`, assert in `tests/eval-keys.nix`.

**A new check file** — register it under `outputs.checks` in `flake.nix`.

**A new harness** — write an ADR first. The v1 list is closed in ADR 0004.

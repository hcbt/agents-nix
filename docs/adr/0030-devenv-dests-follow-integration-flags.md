# Devenv dests follow per-Agent integration flags

Devenv writes a project dest only when that Catalog is filled and at least one Agent that maps to the dest has the matching integration flag on. `agents.mcp.enable` and `agents.claudeSkills` are gone. Shared dests stay one file (never split per Agent). Existing MCP dests that differ are renamed to `*.old` and replaced; identical dests are left in place. There is no `*.agents-nix` breadcrumb. `enterShell` runs in a subshell so `set -u` does not leak into devenv activation. Unmarked skill dests are still refused.

This supersedes ADR-0021 (always write holdouts) and the devenv write-gate in ADR-0028.

MCP dests: `claude-code`, `pi-coding-agent`, `grok`, and `muse-code` share `.mcp.json`; `antigravity-cli` writes `.agents/mcp_config.json`; `codex` writes `.codex/config.toml`; `opencode` writes `opencode.json`. Skills dests: `claude-code` writes `.claude/skills`; the other v1 Agents share `.agents/skills`.

# Project-local MCP writes `.mcp.json` and holdout files

Project-local MCP is in v1. The shared file is `.mcp.json` (Claude, Pi). Holdouts also get a file: Codex `.codex/config.toml`, Grok `.grok/config.toml`, OpenCode `opencode.json`. Muse stays user-home if it has no project MCP path. Creating `.codex/` can make Codex ignore user-global config; accepted.

Takeover of those files is overwrite (ADR 0026), not merge.

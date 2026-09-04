# Unmarked skill dests are refused

If `.agents/skills` or `.claude/skills` exists and does not carry this flake’s marker, skill install fails. The hook will not `mv` that directory to `skills.old`. MCP files use a different rule (overwrite + `*.old`, ADR 0026). Marker filename: `.agents-nix-managed.json`.

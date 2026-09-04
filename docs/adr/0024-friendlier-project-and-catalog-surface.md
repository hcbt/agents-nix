# Catalog UX is a skills map plus `enable`

Devenv and the flake hook use `agents.enable`, `agents.skills.<name> = path | { path, subdir }`, and `agents.mcp.servers`. `enable = true` writes the convention dests (`.agents/skills`, `.claude/skills`, `.mcp.json`, MCP holdouts). There is no dest list and no `skills.sources` nesting. `agents.claudeSkills = false` skips `.claude/skills`.

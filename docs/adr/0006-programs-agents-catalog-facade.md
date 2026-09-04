# Catalogs are declared at `programs.agents`

Superseded by ADR-0027.

Shared MCP, skills, and user instructions are typed under `programs.agents.{mcp,skills,instructions}`. `programs.agents.mcp` is a facade: it assigns Home Manager’s `programs.mcp`, it does not replace it. `programs.mcp.servers` remains valid and merges. The third catalog is `instructions`, not `rules` — Home Manager already uses `rules` for Claude’s extra markdown files under `~/.claude/rules/`.

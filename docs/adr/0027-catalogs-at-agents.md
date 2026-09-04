# Catalogs are declared at `agents`

Shared MCP, skills, and user instructions live under `agents.{mcp,skills,instructions}` in both Home Manager and devenv. `programs.agents` is gone. `agents.mcp` is still a facade over Home Manager’s `programs.mcp`; `programs.mcp.servers` remains valid and merges. The third catalog is still `instructions`, not `rules`.

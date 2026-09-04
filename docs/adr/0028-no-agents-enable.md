---
status: superseded in part by ADR-0030
---

# No `agents.enable`

There is no inheritance master switch. Importing a module writes nothing until catalogs are filled. `agents.mcp.enable` mirrors `programs.mcp.enable`: in Home Manager it assigns `programs.mcp` and does not set `enableMcpIntegration` on any Agent. Devenv writes MCP files when `agents.mcp.enable` is on, and skill dests when `agents.skills` is non-empty. `agents.claudeSkills = false` still skips `.claude/skills`.

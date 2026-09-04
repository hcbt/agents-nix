# Home Manager uses the same catalog types under `programs.agents`

Superseded by ADR-0027.

`programs.agents.skills` and `programs.agents.mcp.servers` match devenv’s `agents.skills` and `agents.mcp.servers`. The option root differs (`programs.agents` vs `agents`) because devenv is not Home Manager. Fan-out to each enabled agent’s home paths stays a Home Manager concern.

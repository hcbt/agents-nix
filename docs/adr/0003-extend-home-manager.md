# Extend Home Manager Agent modules, do not redeclare them

Where Home Manager already owns `programs.mcp` and `programs.<agent>`, this flake assigns `config` and may add new options. It must not redeclare existing options (the module system will conflict). `programs.agents.mcp` is a facade over `programs.mcp` (see ADR 0006). Agents Home Manager does not ship (Grok, Muse) are full modules in this flake, written in the same `programs.<name>` shape.

# `programs.agents.enable` is the inheritance master switch

Superseded by ADR-0028.

It defaults to `false`, so importing `homeManagerModules.default` changes nothing until the consumer turns it on. When it is off, this flake does not copy catalogs onto Agents; `programs.grok.enable` and raw `programs.mcp` still work on their own. When it is on, filled catalogs inherit to every enabled Agent.

# Integration flags stay off until set

This flake does not turn on `enableMcpIntegration`, `enableSkillsIntegration`, or `enableContextIntegration`. Those default false, as Home Manager ships them. An enabled Agent inherits a Catalog only when that Agent’s matching flag is true. Filling `agents.mcp`, `agents.skills`, or `agents.instructions` is not enough.

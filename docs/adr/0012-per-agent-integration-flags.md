# Skills and instructions opt out with `enable*Integration`

The flags stand; defaulting them on is superseded by ADR-0029.

MCP already uses `enableMcpIntegration`. Each Agent also gets `enableSkillsIntegration` and `enableContextIntegration`, default on when that Agent is enabled. Skill attrsets merge, so an empty `skills = { }` cannot turn inheritance off; a flag can. Setting the Agent’s own `context` or extra skill names is still the overlay.

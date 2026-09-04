# Per-agent MCP opt-out is `enableMcpIntegration`

Home Manager already has this flag and ships it off. This flake sets it on (`mkDefault true`) for enabled Agents so the MCP catalog actually inherits. A second `inheritMcp` flag is not added. Extra or replacement servers still go on the Agent’s own MCP settings; the Agent wins on name clash.

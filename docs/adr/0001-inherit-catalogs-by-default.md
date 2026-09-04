# Inherit catalogs by default

Superseded by ADR-0029.

Home Manager’s agent modules leave `enableMcpIntegration` off until the user opts in. This flake does the opposite: MCP servers, skills, and user instructions are declared once and every enabled Agent inherits them, with a per-Catalog disable and override on that Agent. Opt-in inheritance would make the shared catalogs dead by default, which is the failure this module exists to prevent.

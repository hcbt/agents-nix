# Project dests prefer `.agents/skills`

A project install writes `.agents/skills` for every harness that already scans that path (Codex, Muse, Antigravity, Grok, OpenCode, Pi). A separate folder is used only when the harness does not (Claude Code: `.claude/skills`). v1 dest names are `agents` and `claude` only. This does not change Home Manager user-home paths. Dests stay an explicit opt-in list.

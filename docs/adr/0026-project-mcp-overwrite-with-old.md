# Project MCP files are overwritten; a stranger file is moved to `.old`

Devenv is treated as source of truth for project MCP (and, by this choice, the whole holdout config file). If the target file exists and is not ours, it is renamed to `*.old` and replaced. If it is already ours (marker), it is overwritten in place — no new `.old` every shell enter. If `*.old` already exists, it is replaced so the next enter does not fail. Mixed keys (OpenCode theme, Grok UI, Codex model) that were only in the old file are not merged back; put them in Nix later if they must survive.

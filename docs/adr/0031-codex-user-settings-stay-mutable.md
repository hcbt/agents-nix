# Codex user settings stay mutable

`programs.codex.mutableUserSettings` defaults to `true`: agents-nix disables Home Manager's generated `config.toml` symlink and merges its complete generated settings into a writable Codex user file from `modules/home/integrations.nix`. Declarative settings remain Nix-owned while Runtime state survives activation and rollback. This is a compatibility shim for Home Manager issue #9397 and must be removed with its option declaration when Home Manager ships the equivalent behavior.

## Considered options

Codex's `/etc/codex/config.toml` layer was rejected because standalone Home Manager cannot manage it, it requires a separate system-module surface, and the higher-precedence user layer can override it. A Zed-style two-way merge was rejected because it cannot remove settings deleted from Nix. Managing only `mcp_servers` was rejected because Home Manager emits explicit settings, transformed MCP servers, and generated plugin settings as one file.

## Consequences

The mutable path uses an Ownership snapshot in the user's XDG state directory for an ownership-aware three-way merge. It preserves Runtime state, removes previously managed keys that disappear, applies new Declarative settings, retains one recovery copy, skips semantic no-ops, and fails without replacing either live file on invalid TOML. Installation uses a validated temporary file and bounded optimistic retries rather than claiming a lock Codex does not share. `yq-go` provides TOML parsing and emission, so data is preserved while formatting and comments are best-effort.

On first activation, an existing Nix-store symlink supplies the initial Ownership snapshot. An existing regular file is treated conservatively as Runtime state, except that MCP servers are declarative-only. `mutableUserSettings = false` retains Home Manager's existing immutable behavior. Codex versions before 0.2 retain their existing YAML behavior.

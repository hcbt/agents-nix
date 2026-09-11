# OMP is a v1 Agent

oh-my-pi (`omp`) is a CLI harness Home Manager does not ship. This flake provides `programs.omp` in the Grok/Muse shape and adds `omp` to the closed v1 list. Project dests join the shared `.mcp.json` and `.agents/skills` files because OMP already reads both. User-home files stay under `~/.omp/agent/`. `config.yml` and `mcp.json` are writable copies so OMP can lock and rewrite them; the next activation overwrites declared values. This flake does not import oh-my-pi's module or package.

The v1 list is now: `grok`, `muse-code`, `claude-code`, `codex`, `opencode`, `antigravity-cli`, `pi-coding-agent`, `omp`. Still closed.

## Considered options

Extending oh-my-pi's own Home Manager module was rejected: the base options are not in Home Manager, so a solo import of this flake could not assign catalogs. A holdout `.omp/mcp.json` / `.omp/skills` was rejected because ADR 0020 and ADR 0030 prefer shared dests when the harness already scans them. A Codex-style three-way merge for `config.yml` was rejected: oh-my-pi's upstream module already overwrites runtime settings on the next switch.

# Agents

Home Manager and devenv modules for CLI coding harnesses, and the catalogs those harnesses share.

## Language

**Agent**:
A CLI coding harness on the v1 closed list. Home Manager configures it through `programs.<name>`. Devenv names the same Agent under `agents.<name>` and exposes only that Agent’s integration flags.
_Avoid_: editor, IDE fork, GUI, VS Code fork

**Catalog**:
A declaration of MCP servers, skills, or user instructions. An Agent receives a Catalog only when that Agent’s matching integration flag is on.
_Avoid_: bundle, pool, registry, source

**Skill**:
A directory that contains a `SKILL.md` file.
_Avoid_: plugin, command, rule

**Skill id**:
The Catalog name of a Skill: `source/leaf` for a pack (for example `pack-a/review`), or the Nix attribute name for a standalone skill. Two packs may both ship a folder named `review`; the Skill id is what keeps them distinct. On disk a pack skill becomes one directory (`pack-a-review`) so harnesses that only scan one level still see both.
_Avoid_: leaf name, target name

**Source**:
A tree of Skills (usually a git checkout) listed once under the skills Catalog. Every `SKILL.md` directory under it is discovered; the Source name becomes the Skill id prefix.
_Avoid_: input, pack, registry, target

**Pack**:
A Source whose path is a tree of Skill directories, not a single Skill.
_Avoid_: repo, input

**Standalone skill**:
A Catalog entry that is one Skill directory (`SKILL.md` at the path root). Its id is the Nix attribute name you gave it, not the folder name in the source repo.
_Avoid_: explicit skill, extra skill, reserved prefix

**Project-local**:
Installing a Catalog into a project directory (gitignored, nix-managed) as well as into the user home. Same Catalog, different dest. A dest is written only when at least one Agent that maps to it has that Catalog’s integration flag on. An existing skill dest without this flake’s marker is refused. An existing MCP dest that differs is renamed to `*.old` and replaced; an identical dest is left in place.
_Avoid_: vendoring, target, local skills as a second catalog

**Shared dest**:
A project file more than one Agent reads for the same Catalog. Opting in any of those Agents writes that one file with the full Catalog. Never split per Agent.
_Avoid_: per-agent copy, `.mcp.json.grok`

**Holdout**:
A project dest only one Agent reads. Written only when that Agent’s matching flag is on.
_Avoid_: extra config, sidecar

**User instructions**:
The always-loaded markdown file an Agent reads at session start. Filenames differ by Agent (`AGENTS.md`, `CLAUDE.md`); the Catalog is the content, not the filename.
_Avoid_: rules, memory, CLAUDE.md (as the concept)

**Inheritance**:
An Agent receiving a Catalog because that Agent’s matching integration flag is on. Filling a Catalog is not enough. Home Manager also requires the Agent enabled (`package = null` still configures without installing the CLI); devenv has no Agent enable and writes project dests.
_Avoid_: wrapping, sync, target, file sink, master switch

**Overlay**:
Per-Agent additions or replacements on top of an inherited Catalog. The Agent wins on the same name. There is no way to subtract a single inherited item in v1.
_Avoid_: exclude, deny list, filter

**Extension**:
Adding options or assigning `config` for an Agent module Home Manager already ships, without redeclaring options it already owns.
_Avoid_: wrapping, forking, replacing, redeclaring

**Declarative settings**:
Agent configuration whose desired value is supplied by Nix. Declarative settings remain Nix-owned across activations, including when a previously declared key is removed.
_Avoid_: static settings, frozen config

**Runtime state**:
Agent-owned, user-local data written while the Agent runs and not declared through Nix, such as workspace trust decisions and interface bookkeeping. Runtime state survives Home Manager activation and rollback.
_Avoid_: dynamic settings, dirty config

**Ownership snapshot**:
The last successfully applied Declarative settings, retained outside an Agent's configuration file so a later activation can distinguish removed Declarative settings from Runtime state.
_Avoid_: ledger, manifest, baseline

# Agents

Home Manager modules for CLI coding harnesses, and the catalogs those harnesses share.

## Language

**Agent**:
A CLI coding harness configured through a `programs.<name>` Home Manager module.
_Avoid_: editor, IDE fork, GUI, VS Code fork

**Catalog**:
A user-level declaration of MCP servers, skills, or user instructions. Every enabled Agent inherits each Catalog unless that Agent disables or overrides it.
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
Installing the skills Catalog into a project directory (gitignored, nix-managed) as well as into the user home. Same Catalog, different dest. Dests are named explicitly; an unmarked existing dest is refused. The shared project dest is `.agents/skills`; a per-harness folder is added only when that harness does not read `.agents`.
_Avoid_: vendoring, target, local skills as a second catalog

**User instructions**:
The always-loaded markdown file an Agent reads at session start. Filenames differ by Agent (`AGENTS.md`, `CLAUDE.md`); the Catalog is the content, not the filename.
_Avoid_: rules, memory, CLAUDE.md (as the concept)

**Inheritance**:
An enabled Agent receiving a Catalog, only while the agents layer is on. Each Catalog can be turned off or overlaid on that Agent. A disabled Agent gets no files from this flake. Config without installing the CLI is `enable = true` and `package = null`.
_Avoid_: wrapping, sync, target, file sink

**Overlay**:
Per-Agent additions or replacements on top of an inherited Catalog. The Agent wins on the same name. There is no way to subtract a single inherited item in v1.
_Avoid_: exclude, deny list, filter

**Extension**:
Adding options or assigning `config` for an Agent module Home Manager already ships, without redeclaring options it already owns.
_Avoid_: wrapping, forking, replacing, redeclaring

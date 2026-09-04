# Packs are discovered; standalones are named

`programs.agents.skills` (and devenv `agents.skills`) is a map of entries, not a hand-maintained list of skill ids. A pack is a tree: every directory containing `SKILL.md` is in the catalog, with ids prefixed by the entry name. A standalone is one skill directory; its id is the Nix key. An allowlist is out of v1 — naming a pack is opting into all of its skills.

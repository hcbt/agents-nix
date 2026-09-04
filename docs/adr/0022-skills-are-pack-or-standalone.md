# A skills entry is a pack or a standalone skill

Each `agents.skills.<name>` (and the same under `programs.agents.skills`) is either a path or `{ path, subdir }`. If `SKILL.md` is at the path root, it is one skill. Otherwise it is a pack: `subdir` defaults to `"skills"`. v1 does not cherry-pick a subset of a pack; point at that skill’s directory as a standalone entry instead.

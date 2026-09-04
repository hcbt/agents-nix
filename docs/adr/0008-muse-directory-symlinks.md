# Muse skills are directory symlinks, not copied trees

Muse skips a `SKILL.md` that is itself a symlink, but follows a symlinked skill directory. Recursively linking a skill folder (a real directory of file symlinks) makes `SKILL.md` a symlink. This flake links each skill as one directory. Copying into the home directory is not the default.

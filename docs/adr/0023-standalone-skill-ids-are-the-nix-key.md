# Standalone skill ids are the Nix key

A standalone entry `my-review = ./review` installs as `my-review` (directory and `SKILL.md` `name:`). The folder name in the source tree is ignored. Two standalones cannot share a key; that is an eval error. Pack skills still get `source-leaf` prefixes because you type one key for a whole tree of generic folder names.

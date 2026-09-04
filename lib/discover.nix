{ lib }:
let
  inherit (import ./frontmatter.nix { inherit lib; }) setFrontmatterName;

  walkSkillDirs =
    dir: rel:
    let
      entries = builtins.readDir dir;
      subdirs = lib.filterAttrs (_: t: t == "directory") entries;
      this =
        if rel != "" && entries ? "SKILL.md" then
          [
            {
              relPath = rel;
              leaf = lib.last (lib.splitString "/" rel);
            }
          ]
        else
          [ ];
    in
    this
    ++ lib.concatLists (
      lib.mapAttrsToList (
        name: _: walkSkillDirs (dir + "/${name}") (if rel == "" then name else "${rel}/${name}")
      ) subdirs
    );

  isStandalone = path: builtins.pathExists (path + "/SKILL.md");

  normalizeEntry =
    name: value:
    if builtins.isAttrs value && value ? path then
      {
        inherit name;
        path = value.path;
        subdir = value.subdir or "skills";
      }
    else
      {
        inherit name;
        path = value;
        subdir = "skills";
      };

  packSkills =
    name: path: subdir:
    let
      root = if subdir == "" then path else path + "/${subdir}";
    in
    map (s: {
      id = "${name}-${s.leaf}";
      source = name;
      root = path;
      relPath = if subdir == "" then s.relPath else "${subdir}/${s.relPath}";
      storePath = root + "/${s.relPath}";
    }) (walkSkillDirs root "");

  standaloneSkill = name: path: {
    id = name;
    source = name;
    root = path;
    relPath = "";
    storePath = path;
  };
in
{
  inherit setFrontmatterName isStandalone normalizeEntry;

  discover =
    skills:
    let
      entries = lib.mapAttrsToList (
        name: value:
        let
          e = normalizeEntry name value;
        in
        if isStandalone e.path then [ (standaloneSkill name e.path) ] else packSkills name e.path e.subdir
      ) skills;
      list = lib.concatLists entries;
      ids = map (s: s.id) list;
    in
    if lib.length ids != lib.length (lib.unique ids) then
      throw "agents-nix: duplicate skill ids: ${lib.concatStringsSep ", " ids}"
    else
      lib.listToAttrs (
        map (s: {
          name = s.id;
          value = s;
        }) list
      );
}

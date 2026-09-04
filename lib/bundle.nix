{ lib }:
let
  inherit (import ./discover.nix { inherit lib; }) discover setFrontmatterName;
in
{
  bundle =
    {
      pkgs,
      skills,
    }:
    let
      catalog = discover skills;
      mkSkill =
        id: skill:
        let
          original = builtins.readFile (skill.storePath + "/SKILL.md");
          rewritten = setFrontmatterName id original;
          skillMd = pkgs.writeText "${id}-SKILL.md" rewritten;
        in
        pkgs.runCommand "agent-skill-${id}" { src = skill.storePath; } ''
          mkdir -p "$out"
          cp -aL "$src"/. "$out/"
          chmod -R u+w "$out"
          cp ${skillMd} "$out/SKILL.md"
        '';
    in
    lib.mapAttrs mkSkill catalog;
}

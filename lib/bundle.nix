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
        pkgs.runCommand "agent-skill-${id}" { } ''
          mkdir -p "$out"
          cp -aL ${lib.escapeShellArg (toString skill.storePath)}/. "$out/"
          cp ${skillMd} "$out/SKILL.md"
        '';
    in
    lib.mapAttrs mkSkill catalog;
}

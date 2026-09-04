{ lib }:
let
  isDelimiter = line: builtins.match "[[:space:]]*---[[:space:]]*" line != null;
  isNameLine = line: builtins.match "[[:space:]]*name:.*" line != null;
in
{
  setFrontmatterName =
    newName: content:
    let
      lines = lib.splitString "\n" content;
      step =
        acc: line:
        let
          delim = isDelimiter line;
          acc' = acc // {
            depth = acc.depth + (if delim then 1 else 0);
          };
        in
        if acc.done then
          acc' // { out = acc.out ++ [ line ]; }
        else if delim then
          acc' // { out = acc.out ++ [ line ]; }
        else if acc'.depth == 1 && isNameLine line then
          acc'
          // {
            done = true;
            out = acc.out ++ [ "name: ${newName}" ];
          }
        else
          acc' // { out = acc.out ++ [ line ]; };
      res = lib.foldl step {
        done = false;
        depth = 0;
        out = [ ];
      } lines;
    in
    if res.depth < 2 || !res.done then content else lib.concatStringsSep "\n" res.out;
}

{ lib }:
let
  isUpper = c: builtins.match "[A-Z]" c != null;
  isLowerOrDigit = c: builtins.match "[a-z0-9]" c != null;
  isCamel = s: builtins.match "[a-z][a-zA-Z0-9]*[A-Z][a-zA-Z0-9]*" s != null;

  camelToSnake =
    s:
    let
      chars = lib.stringToCharacters s;
      mapped = lib.imap0 (
        i: c: if isUpper c && i > 0 && isLowerOrDigit (builtins.elemAt chars (i - 1)) then "_${c}" else c
      ) chars;
    in
    lib.toLower (lib.concatStrings mapped);

  toFileKeys =
    value:
    if lib.isDerivation value then
      value
    else if builtins.isList value then
      map toFileKeys value
    else if builtins.isAttrs value then
      lib.mapAttrs' (
        name: v: lib.nameValuePair (if isCamel name then camelToSnake name else name) (toFileKeys v)
      ) value
    else
      value;
in
{
  inherit camelToSnake toFileKeys;
}

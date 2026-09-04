{ pkgs, ... }:

{
  packages = [
    pkgs.git
    pkgs.nixfmt
  ];
}

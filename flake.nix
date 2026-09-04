{
  description = "Home Manager and devenv modules for CLI coding agents";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      agentsLib = import ./lib { inherit lib; };
    in
    {
      homeManagerModules.default = import ./modules/home;
      devenvModules.default = import ./modules/devenv;
      lib = agentsLib;
    };
}

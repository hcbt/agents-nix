{
  description = "Home Manager and devenv modules for CLI coding agents";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      agentsLib = import ./lib { inherit lib; };
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      homeManagerModules.default = import ./modules/home;
      devenvModules.default = import ./modules/devenv;
      lib = agentsLib;
      checks = forAllSystems (pkgs: {
        eval-hm = import ./tests/eval-hm.nix { inherit pkgs; };
        eval-devenv = import ./tests/eval-devenv.nix { inherit pkgs; };
      });
    };
}

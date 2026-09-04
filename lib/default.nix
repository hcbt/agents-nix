{ lib }:
let
  discoverLib = import ./discover.nix { inherit lib; };
  bundleLib = import ./bundle.nix { inherit lib; };
  installLib = import ./install.nix { inherit lib; };
in
{
  inherit (discoverLib) discover setFrontmatterName isStandalone;
  inherit (bundleLib) bundle;
  inherit (installLib) mkProjectHook markerName;
}

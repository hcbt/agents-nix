# Flake exports a Home Manager module, a devenv module, and a `lib`

`homeManagerModules.default` is the Home Manager entry. `devenvModules.default` is the devenv entry. `lib` is the shared engine: discover entries, build a flat bundle, install that bundle into a dest. The Home Manager module uses discover + bundle, then sets `programs.<agent>.skills`. Project-local uses all three. No flake apps in v1.

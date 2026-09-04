# Devenv options live under `agents.*`, not `programs.*`

Home Manager now uses the same `agents` root (ADR-0027). Devenv still must not declare `programs.*`.

`devenvModules.default` is a second frontend on `lib`. Sources and dests have the same shape as Home Manager (`{ path, subdir }`, explicit dest names) but the option root is `agents.skills.*`. Declaring `programs.agents` inside devenv would pretend devenv is Home Manager. `lib.mkProjectSkillsHook` remains for flakes that do not use devenv. Managed dests are marked with `.agents-nix-managed.json`.

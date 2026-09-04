{ pkgs }:
let
  inherit (pkgs) lib;
  keys = import ../lib/file-keys.nix { inherit lib; };
  inherit (keys) camelToSnake toFileKeys;
in
assert camelToSnake "mcpServers" == "mcp_servers";
assert camelToSnake "schemaVersion" == "schema_version";
assert camelToSnake "defaultSkillsInstallsPurged" == "default_skills_installs_purged";
assert camelToSnake "startupTimeoutSec" == "startup_timeout_sec";
assert
  toFileKeys {
    marketplace.defaultSkillsInstallsPurged = true;
    ui.maxThoughtsWidth = 120;
    mcpServers.linear.startupTimeoutSec = 60;
  } == {
    marketplace.default_skills_installs_purged = true;
    ui.max_thoughts_width = 120;
    mcp_servers.linear.startup_timeout_sec = 60;
  };
assert
  toFileKeys { env.CONTEXT7_API_KEY = "x"; } == {
    env.CONTEXT7_API_KEY = "x";
  };
assert
  toFileKeys { marketplace.default_skills_installs_purged = true; } == {
    marketplace.default_skills_installs_purged = true;
  };
pkgs.runCommand "eval-keys-ok" { } "touch $out"

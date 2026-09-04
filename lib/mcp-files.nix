{ lib }:
let
  # Project files do not use Home Manager's MCP transformers. String env
  # values pass through; `{ file = path; }` becomes a wrapper at install
  # time only for stdio servers when pkgs is available (see wrapEnv).
  asStringEnv =
    env: lib.mapAttrs (_: v: if builtins.isAttrs v && v ? file then v.file else v) (env or { });

  jsonServer =
    server:
    lib.filterAttrs (_: v: v != null && v != { } && v != [ ]) {
      command = server.command or null;
      args = server.args or null;
      env = if server ? env then asStringEnv server.env else null;
      url = server.url or null;
      headers = server.headers or null;
      type = server.type or null;
    };

  opencodeServer =
    server:
    if server ? url then
      {
        type = "remote";
        url = server.url;
      }
      // lib.optionalAttrs (server ? headers) { inherit (server) headers; }
    else
      {
        type = "local";
        command = [ server.command ] ++ (server.args or [ ]);
      }
      // lib.optionalAttrs (server ? env) { environment = asStringEnv server.env; };
in
{
  inherit jsonServer opencodeServer;

  mcpJson = servers: { mcpServers = lib.mapAttrs (_: jsonServer) servers; };

  grokToml = servers: { mcp_servers = lib.mapAttrs (_: jsonServer) servers; };

  codexToml = servers: { mcp_servers = lib.mapAttrs (_: jsonServer) servers; };

  opencodeJson = servers: { mcp = lib.mapAttrs (_: opencodeServer) servers; };
}

{
  lib,
  config,
  ...
}:
let
  cfg = config.services.auth-server.postgres;
  inherit (import ./scripts/constants.nix { inherit config; }) dbPermissionsAndOwnership;
in
{
  options.services.auth-server.postgres = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Database user.";
      default = "handygleam";
    };
    dbName = lib.mkOption {
      type = lib.types.str;
      description = "Database user.";
      default = "handygleam";
    };
  };

  config = {
    services.postgres = {
      enable = true;
      initialDatabases = [
        {
          name = cfg.dbName;
        }
      ];
      listen_addresses = "*";
      initialScript = ''
        CREATE ROLE postgres WITH LOGIN SUPERUSER;
        CREATE ROLE ${cfg.user} WITH LOGIN;

        ${dbPermissionsAndOwnership}
      '';
    };
  };
}

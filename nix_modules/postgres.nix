{
  lib,
  config,
  ...
}:
let
  cfg = config.services.auth-server.postgres;
in
{
  options.services.auth-server.postgres = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "Database user.";
      default = "auth_server";
    };
    dbName = lib.mkOption {
      type = lib.types.str;
      description = "Database user.";
      default = "auth_server";
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
        GRANT ALL PRIVILEGES ON DATABASE ${cfg.dbName} TO ${cfg.user};
        \c ${cfg.dbName}
        GRANT ALL ON SCHEMA public TO ${cfg.user};
      '';
    };
  };
}

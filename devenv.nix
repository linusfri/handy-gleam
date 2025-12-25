{
  pkgs,
  inputs,
  ...
}:
let
  gleamPkgs = import inputs.gleam-pkgs { system = pkgs.stdenv.system; };
in
{
  imports = [
    ./nix_modules/postgres.nix
    ./nix_modules/scripts/db.nix
  ];

  config = {
    hosts."auth-server.local" = "127.0.0.1";

    packages = with pkgs; [
      git
      inotify-tools
      dbmate
    ];

    env = {
      SECRET_KEY = "supersecret";
      AUTH_ENDPOINT = "keycloak.friikod.se/realms/auth-server/protocol/openid-connect";
      ADMIN_ENDPOINT = "keycloak.friikod.se/admin/realms/auth-server";
      STATIC_DIRECTORY = "static";
    };

    services.auth-server.postgres = {
      user = "auth_server";
      dbName = "auth_server";
    };

    processes.app = {
      exec = ''
        gleam run
      '';
      process-compose = {
        depends_on.postgres.condition = "process_healthy";
      };
    };

    languages.gleam = {
      enable = true;
      package = gleamPkgs.gleam;
    };
  };
}

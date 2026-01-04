{
  pkgs,
  inputs,
  config,
  ...
}:
let
  gleamPkgs = import inputs.gleam-pkgs { system = pkgs.stdenv.system; };
  domain = "auth-server.local";

  inherit (import ./nix_modules/nginx/locations.nix) root;
in
{
  imports = [
    ./nix_modules/postgres.nix
    ./nix_modules/scripts/db.nix
  ];

  config = {

    hosts."${domain}" = "127.0.0.1";
    certificates = builtins.attrNames config.hosts;

    packages = with pkgs; [
      git
      inotify-tools
      dbmate
    ];

    env = {
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

    services.nginx = {
      enable = true;
      httpConfig = ''
        server {
          listen 8080;
          server_name ${domain};

          location / {
            ${root}
          }

          client_max_body_size 100M;
        }

        server {
          listen 4443 ssl http2;
          server_name ${domain};

          ssl_certificate ${config.env.DEVENV_STATE}/mkcert/${domain}.pem;
          ssl_certificate_key ${config.env.DEVENV_STATE}/mkcert/${domain}-key.pem;
          
          ssl_protocols TLSv1.2 TLSv1.3;
          ssl_ciphers HIGH:!aNULL:!MD5;
          ssl_prefer_server_ciphers on;

          location / {
            ${root}
          }

          client_max_body_size 100M;
        }
      '';
    };

    languages.gleam = {
      enable = true;
      package = gleamPkgs.gleam;
    };
  };
}

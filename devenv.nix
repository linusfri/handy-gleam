{
  pkgs,
  inputs,
  config,
  ...
}:
let
  gleamPkgs = import inputs.gleam-pkgs { system = pkgs.stdenv.system; };
  localDomain = "auth-server.local";
in
{
  imports = [
    ./nix_modules/postgres.nix
    ./nix_modules/scripts/db.nix
  ];

  config = {
    hosts."${localDomain}" = "127.0.0.1";

    packages = with pkgs; [
      git
      inotify-tools
      dbmate
      cloudflared
    ];

    env = {
      AUTH_ENDPOINT = "keycloak.friikod.se/realms/auth-server/protocol/openid-connect";
      ADMIN_ENDPOINT = "keycloak.friikod.se/admin/realms/auth-server";
      FACEBOOK_BASE_URL = "graph.facebook.com/v24.0";
      FACEBOOK_REDIRECT_URI = "${config.env.CLOUDFLARE_TUNNEL_URL}/facebook-instagram/long-lived-token";
      CLOUDFLARE_TUNNEL_URL = "https://auth-server-local.friikod.se";
      STATIC_DIRECTORY = "static";
    };

    services.auth-server.postgres = {
      user = "auth_server";
      dbName = "auth_server";
    };

    processes.cloudflare-tunnel.exec = ''
      cloudflared tunnel run --token $CLOUDFLARE_TUNNEL_TOKEN
    '';

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

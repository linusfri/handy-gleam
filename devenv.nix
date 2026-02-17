{
  pkgs,
  inputs,
  config,
  ...
}:
let
  gleamPkgs = import inputs.gleam-pkgs { system = pkgs.stdenv.system; };
  localDomain = "handy-gleam.local";
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
      APP_URL = config.env.CLOUDFLARE_TUNNEL_URL;
      FACEBOOK_BASE_URL = "graph.facebook.com/v24.0";
      FACEBOOK_REDIRECT_URI = "${config.env.CLOUDFLARE_TUNNEL_URL}/facebook-instagram/long-lived-token";
      CLOUDFLARE_TUNNEL_URL = "https://handy-gleam-local.friikod.se";
      STATIC_UPLOAD_PATH = "static";
      STATIC_SERVE_PATH = "/static";
    };

    services.handy-gleam.postgres = {
      user = "handygleam";
      dbName = "handygleam";
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

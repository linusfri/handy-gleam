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
  ];

  config = {
    hosts."auth-server.local" = "127.0.0.1";

    packages = with pkgs; [
      git
      inotify-tools
    ];

    env = {
      SECRET_KEY = "supersecret";
      AUTH_ENDPOINT = "keycloak.friikod.se/realms/auth-server/protocol/openid-connect";
    };

    processes.app.exec = ''
      gleam run
    '';

    languages.gleam = {
      enable = true;
      package = gleamPkgs.gleam;
    };
  };
}

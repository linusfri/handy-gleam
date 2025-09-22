{ pkgs, inputs, ... }:
let
  gleamPkgs = import inputs.gleam-pkgs { system = pkgs.stdenv.system; };
in
{
  config = {
    hosts."auth-server.local" = "127.0.0.1";

    packages = with pkgs; [ git ];

    env = {
      SECRET_KEY = "supersecret";
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

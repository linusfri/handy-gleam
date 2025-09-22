{ pkgs, lib, config, inputs, ... }:
let
  gleamPkgs = import inputs.gleam-pkgs { system = pkgs.stdenv.system; };
in
{
  config = {
    packages = with pkgs; [ git ];

    env = {
      SECRET_KEY = "supersecret";
    };

    languages.gleam = {
      enable = true;
      package = gleamPkgs.gleam;
    };
  };
}

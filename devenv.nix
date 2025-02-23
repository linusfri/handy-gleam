{ pkgs, lib, config, inputs, ... }:

{
  config = {
    packages = with pkgs; [ git ];

    env = {
      SECRET_KEY = "supersecret";
    };

    languages.gleam.enable = true;
  };
}

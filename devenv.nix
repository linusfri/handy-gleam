{ pkgs, lib, config, inputs, ... }:

{
  config = {
    packages = with pkgs; [ git ];

    languages.gleam.enable = true;
  };
}

{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-24.11";
    gleam-nix.url = "github:arnarg/nix-gleam";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      gleam-nix,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = { inherit system; };
      in
      {
        packages.auth-server = pkgs.callPackage ./. { };
      }
    );
}

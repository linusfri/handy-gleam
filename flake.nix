{
  description = "Flake for build gleam application.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-24.11";
    nix-gleam.url = "github:arnarg/nix-gleam";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-gleam,
      utils,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            nix-gleam.overlays.default
          ];
        };
      in
      {
        packages.auth-server = pkgs.callPackage ./. { };
        packages.default = self.outputs.packages.${system}.auth-server;
      }
    );
}

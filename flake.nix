{
  description = "Flake for build gleam application.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=release-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-gleam.url = "github:arnarg/nix-gleam";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
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

        pkgsUnstable = import nixpkgs-unstable {
          inherit system;
          overlays = [
            nix-gleam.overlays.default
          ];
        };
      in
      {
        packages.auth-server = pkgs.callPackage ./. { pkgs = pkgsUnstable; };
        packages.default = self.outputs.packages.${system}.auth-server;
      }
    );
}

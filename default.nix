{ pkgs, ... }:

pkgs.buildGleamApplication {
  # The pname and version will be read from the `gleam.toml`
  # Can be overwritten here.
  # pname = "auth_server";
  # version = "1.0.0";

  # The target is read from the `gleam.toml` file too.
  # Default is "erlang" if nothing is specified but
  # this can also be overwritten here too:
  # target = "javascript";

  # Erlang package can be overridden but defaults to
  # `pkgs.erlang`.
  # erlangPackage = pkgs.erlang_nox;

  buildInputs = with pkgs; [ erlang_27 ];

  src = ./.;
}

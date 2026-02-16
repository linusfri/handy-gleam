{
  config,
  ...
}:
let
  dbCfg = config.services.handy-gleam.postgres;
  inherit (import ./constants.nix { inherit config; }) dbPermissionsAndOwnership;
in
{
  config = {
    scripts.set-unix-db-url.exec = ''
      echo 'export DATABASE_URL="postgres://${dbCfg.user}@/${dbCfg.dbName}?host=$PGHOST&sslmode=disable"'
    '';

    scripts.dbmate-cli.exec = ''
      source <(set-unix-db-url)

      dbmate "$@"
    '';

    scripts.set-squirrel-db-url.exec = ''
      echo 'export DATABASE_URL="postgres://postgres@127.0.0.1:5432/${dbCfg.dbName}"'
    '';

    scripts.migrate-fresh.exec = ''
      echo "Dropping database..."
      dbmate-cli drop

      echo "Creating database and setting up permissions..."
      psql -U postgres << EOF
      CREATE DATABASE ${dbCfg.dbName};
      ${dbPermissionsAndOwnership}
      EOF

      echo "Running migrations..."
      dbmate-cli up
    '';

    scripts.gleam-db-generate.exec = ''
      source <(set-squirrel-db-url)

      echo $DATABASE_URL

      gleam run -m squirrel
    '';
  };
}

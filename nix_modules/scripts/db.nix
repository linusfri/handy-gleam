{
  config,
  ...
}:
let
  dbCfg = config.services.auth-server.postgres;
in
{
  scripts.set-unix-db-url.exec = ''
    echo 'export DATABASE_URL="postgres://${dbCfg.user}@/${dbCfg.dbName}?host=$PGHOST&sslmode=disable"'
  '';

  scripts.set-squirrel-db-url.exec = ''
    echo 'export DATABASE_URL="postgres://postgres@127.0.0.1:5432/${dbCfg.dbName}"'
  '';

  scripts.dbmate-cli.exec = ''
    source <(set-unix-db-url)

    dbmate "$@"
  '';

  scripts.gleam-db-generate.exec = ''
    source <(set-squirrel-db-url)

    echo $DATABASE_URL

    gleam run -m squirrel
  '';
}

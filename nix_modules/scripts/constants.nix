{config, ...}:
let
  dbCfg = config.services.auth-server.postgres;
in
{
  dbPermissionsAndOwnership = ''
    ALTER DATABASE ${dbCfg.dbName} OWNER TO ${dbCfg.user};
    GRANT ALL PRIVILEGES ON DATABASE ${dbCfg.dbName} TO ${dbCfg.user};
    \c ${dbCfg.dbName}
    GRANT ALL ON SCHEMA public TO ${dbCfg.user};
  '';
}
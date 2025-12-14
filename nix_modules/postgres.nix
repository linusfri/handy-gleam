{
  ...
}:
{
  config = {
    services.postgres = {
      enable = true;
      initialDatabases = [
        {
          name = "auth_server";
        }
      ];
      initialScript = ''
        CREATE ROLE auth_server WITH LOGIN;
        GRANT ALL PRIVILEGES ON DATABASE auth_server TO auth_server;
        \c auth_server
        GRANT ALL ON SCHEMA public TO auth_server;
      '';
    };
  };
}

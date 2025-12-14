{
  ...
}:
{
  config = {
    services.postgres = {
      enable = true;
      initialDatabases = [
        { name = "auth_server"; }
      ];
    };
  };
}

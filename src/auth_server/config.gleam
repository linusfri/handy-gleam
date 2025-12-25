import envoy
import gleam/io
import gleam/list
import wisp

pub type Config {
  Config(
    secret_key: String,
    auth_endpoint: String,
    admin_endpoint: String,
    pghost: String,
    static_directory: String,
  )
}

pub fn get_config() -> Config {
  let envs = [
    "SECRET_KEY",
    "AUTH_ENDPOINT",
    "ADMIN_ENDPOINT",
    "PGHOST",
    "STATIC_DIRECTORY",
  ]

  list.each(envs, fn(env) {
    case envoy.get(env) {
      Ok(_) -> Nil
      Error(_) -> {
        io.println(env <> " is not set. The program will panic.")
        panic as "Set all required envs to start server."
      }
    }
  })

  let assert Ok(secret_key) = envoy.get("SECRET_KEY")
  let assert Ok(auth_endpoint) = envoy.get("AUTH_ENDPOINT")
  let assert Ok(admin_endpoint) = envoy.get("ADMIN_ENDPOINT")
  let assert Ok(pghost) = envoy.get("PGHOST")
  let assert Ok(static_directory) = envoy.get("STATIC_DIRECTORY")
  Config(secret_key, auth_endpoint, admin_endpoint, pghost, static_directory)
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("assets")
  priv_directory <> "/static"
}

pub const config = get_config

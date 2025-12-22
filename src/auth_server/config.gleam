import envoy
import gleam/io
import gleam/list

pub type Config {
  Config(secret_key: String, auth_endpoint: String, pghost: String)
}

pub fn get_config() -> Config {
  let envs = ["SECRET_KEY", "AUTH_ENDPOINT", "PGHOST"]

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
  let assert Ok(pghost) = envoy.get("PGHOST")
  Config(secret_key, auth_endpoint, pghost)
}

pub const config = get_config

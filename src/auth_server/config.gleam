import envoy
import gleam/io
import gleam/list

pub type Config {
  Config(secret_key: String, auth_endpoint: String)
}

pub fn get_config() -> Config {
  let envs = ["SECRET_KEY", "AUTH_ENDPOINT"]

  list.each(envs, fn(env) {
    case envoy.get(env) {
      Ok(_) -> io.println(env <> " is ok.")
      Error(_) -> {
        io.println(env <> " is not set. The program will panic.")
        panic as "Set all required envs to start server."
      }
    }
  })

  let assert Ok(secret_key) = envoy.get("SECRET_KEY")
  let assert Ok(auth_endpoint) = envoy.get("AUTH_ENDPOINT")
  Config(secret_key, auth_endpoint)
}

pub const config = get_config

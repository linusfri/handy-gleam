import envoy
import gleam/io
import gleam/list
import wisp

pub type Config {
  Config(
    secret_key: String,
    auth_endpoint: String,
    admin_endpoint: String,
    app_url: String,
    pghost: String,
    static_upload_path: String,
    static_serve_path: String,
    facebook_base_url: String,
    facebook_app_id: String,
    facebook_redirect_uri: String,
    facebook_state_param: String,
    facebook_app_secret: String,
  )
}

pub fn get_config() -> Config {
  let envs = [
    "SECRET_KEY",
    "AUTH_ENDPOINT",
    "ADMIN_ENDPOINT",
    "APP_URL",
    "PGHOST",
    "STATIC_UPLOAD_PATH",
    "STATIC_SERVE_PATH",
    "FACEBOOK_BASE_URL",
    "FACEBOOK_APP_ID",
    "FACEBOOK_REDIRECT_URI",
    "FACEBOOK_STATE_PARAM",
    "FACEBOOK_APP_SECRET",
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
  let assert Ok(app_url) = envoy.get("APP_URL")
  let assert Ok(pghost) = envoy.get("PGHOST")
  let assert Ok(static_upload_path) = envoy.get("STATIC_UPLOAD_PATH")
  let assert Ok(static_serve_path) = envoy.get("STATIC_SERVE_PATH")
  let assert Ok(facebook_base_url) = envoy.get("FACEBOOK_BASE_URL")
  let assert Ok(facebook_app_id) = envoy.get("FACEBOOK_APP_ID")
  let assert Ok(facebook_redirect_uri) = envoy.get("FACEBOOK_REDIRECT_URI")
  let assert Ok(facebook_state_param) = envoy.get("FACEBOOK_STATE_PARAM")
  let assert Ok(facebook_app_secret) = envoy.get("FACEBOOK_APP_SECRET")

  Config(
    secret_key,
    auth_endpoint,
    admin_endpoint,
    app_url,
    pghost,
    static_upload_path,
    static_serve_path,
    facebook_base_url,
    facebook_app_id,
    facebook_redirect_uri,
    facebook_state_param,
    facebook_app_secret,
  )
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("assets")
  priv_directory <> "/static"
}

pub const config = get_config

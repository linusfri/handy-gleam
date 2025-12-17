import auth_server/auth/auth_utils
import auth_server/config.{config}
import auth_server/utils/api_client
import gleam/http
import gleam/http/request as http_request
import gleam/json
import gleam/string
import wisp

pub fn get_user(access_token: String) {
  let site_uri = auth_utils.get_default_site_uri()
  let user_info_request =
    http_request.Request(
      method: http.Get,
      headers: [#("Authorization", "Bearer " <> access_token)],
      body: "",
      scheme: http.Https,
      host: config().auth_endpoint,
      port: site_uri.port,
      path: "/userinfo",
      query: site_uri.query,
    )

  api_client.send_request(user_info_request)
}

pub fn get_current_user(req, _) {
  use <- wisp.require_method(req, http.Get)
  let token = http_request.get_header(req, "Authorization")

  let token = case token {
    Ok(auth_header) -> {
      case string.split(auth_header, " ") {
        ["Bearer", token] | ["bearer", token] -> token
        _ -> auth_header
      }
    }
    _ -> ""
  }

  case get_user(token) {
    Ok(user_data) -> {
      case auth_utils.user_decoder(user_data) {
        Ok(user) -> {
          let user_json = auth_utils.user_encoder(user)
          wisp.json_response(json.to_string(user_json), 200)
        }
        Error(_) -> wisp.json_response("Failed to decode user", 500)
      }
    }
    Error(wisp_error) -> wisp_error
  }
}

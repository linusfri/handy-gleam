import auth_server/auth/auth_utils
import auth_server/config.{config}
import auth_server/lib/user/transform.{user_decoder}
import auth_server/utils/api_client
import gleam/http
import gleam/http/request as http_request
import wisp

/// Requests user from authentication backend. In this case keycloak.
pub fn get_user_request(access_token: String) {
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

/// Gets a decoded user for use internally.
pub fn get_session_user(req) {
  let token = auth_utils.get_token(req)

  case get_user_request(token) {
    Ok(user_data) ->
      case user_decoder(user_data) {
        Ok(user) -> Ok(user)

        Error(_) -> Error(wisp.json_response("Failed to decode user", 500))
      }
    Error(wisp_error) -> Error(wisp_error)
  }
}

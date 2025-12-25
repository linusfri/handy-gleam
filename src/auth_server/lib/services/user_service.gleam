import auth_server/config.{config}
import auth_server/lib/auth/auth_utils
import auth_server/lib/utils/api_client
import gleam/http
import gleam/http/request as http_request

/// Requests user from authentication backend. In this case keycloak.
pub fn request_get_user(access_token: String) {
  let site_uri = auth_utils.get_default_auth_uri()
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

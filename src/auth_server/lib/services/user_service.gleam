import auth_server/config.{config}
import auth_server/lib/auth/auth_utils
import auth_server/lib/user/transform as user_transform
import auth_server/lib/utils/api_client
import auth_server/lib/utils/logger
import gleam/dynamic/decode
import gleam/http
import gleam/http/request as http_request
import gleam/json
import gleam/result

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

  use user_response <- result.try(api_client.send_request(user_info_request))
  use user_data <- result.try(
    json.parse(user_response.body, decode.dynamic)
    |> result.map_error(fn(err) {
      logger.log_error_with_context("user_service:request_get_user", err)
      "Failed to parse user response as JSON"
    }),
  )
  use decoded_user <- result.try(
    user_transform.user_decoder(user_data)
    |> result.map_error(fn(err) {
      logger.log_error_with_context("user_service:request_get_user", err)
      "Failed to decode user data"
    }),
  )
  Ok(decoded_user)
}

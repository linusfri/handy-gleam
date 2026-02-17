import gleam/dynamic/decode
import gleam/http
import gleam/http/request as http_request
import gleam/json
import gleam/result
import handygleam/config.{config}
import handygleam/lib/models/auth/auth_utils
import handygleam/lib/models/error/app_error.{
  type AppError, AppError, ExternalApi, Unauthorized,
}
import handygleam/lib/models/user/user_transform
import handygleam/lib/utils/api_client
import handygleam/lib/utils/logger

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

  use user_response <- result.try(
    api_client.send_request(user_info_request)
    |> result.map_error(fn(err) {
      logger.log_error_with_context("user_service:request_get_user", err)
      AppError(
        error: ExternalApi,
        message: "Failed to get user from auth server",
      )
    }),
  )

  case user_response.status {
    200 -> {
      use user_data <- result.try(
        json.parse(user_response.body, decode.dynamic)
        |> result.map_error(fn(err) {
          logger.log_error_with_context("user_service:request_get_user", err)
          AppError(
            error: ExternalApi,
            message: "Failed to parse user response as JSON",
          )
        }),
      )
      use decoded_user <- result.try(
        user_transform.user_decoder(user_data)
        |> result.map_error(fn(err) {
          logger.log_error_with_context("user_service:request_get_user", err)
          AppError(
            error: ExternalApi,
            message: "Failed to decode user data",
          )
        }),
      )
      Ok(decoded_user)
    }
    401 -> Error(AppError(error: Unauthorized, message: "Unauthorized"))
    _ ->
      Error(
        AppError(
          error: ExternalApi,
          message: user_response.body,
        ),
      )
  }
}

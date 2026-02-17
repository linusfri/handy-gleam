import gleam/http.{Post}
import gleam/http/request
import handygleam/config.{config}
import handygleam/lib/models/auth/auth_transform
import handygleam/lib/models/auth/auth_utils
import handygleam/lib/models/auth/oauth
import handygleam/lib/models/error/app_error.{
  AppError, InvalidPayload, to_http_response,
}
import handygleam/lib/models/user/user_types.{type User}
import handygleam/lib/utils/api_client
import handygleam/lib/utils/logger
import wisp.{type Request}

pub fn login(req: Request) {
  use <- wisp.require_method(req, Post)
  use json_body <- wisp.require_json(req)

  case auth_transform.login_form_decoder(json_body) {
    Ok(form_data) ->
      case oauth.build_login_response(form_data) {
        Ok(login_response) -> login_response
        Error(error_response) -> to_http_response(error_response)
      }
    Error(err) -> {
      logger.log_error_with_context("auth:login", err)
      to_http_response(AppError(
        error: InvalidPayload,
        message: "Invalid login JSON body",
      ))
    }
  }
}

pub fn logout(req: Request, user: User) {
  use <- wisp.require_method(req, Post)

  let site_uri = auth_utils.get_default_admin_url()

  let access_token = auth_utils.get_session_token(req)

  let user_logout_request =
    request.Request(
      method: http.Post,
      headers: [#("Authorization", "Bearer " <> access_token)],
      body: "",
      scheme: http.Https,
      host: config().admin_endpoint,
      port: site_uri.port,
      path: "/users/" <> user.sub <> "/logout",
      query: site_uri.query,
    )

  case api_client.send_request(user_logout_request) {
    Ok(res) if res.status > 200 && res.status < 300 ->
      wisp.json_response("User logged out", res.status)
    Ok(res) -> wisp.json_response(res.body, res.status)
    Error(error_response) -> to_http_response(error_response)
  }
}

pub fn refresh_token(req: Request) {
  use <- wisp.require_method(req, Post)
  use json_body <- wisp.require_json(req)

  case auth_transform.refresh_token_request_decoder(json_body) {
    Ok(token_request) ->
      case oauth.build_refresh_response(token_request) {
        Ok(token) -> token
        Error(error_response) -> to_http_response(error_response)
      }
    Error(_) ->
      to_http_response(AppError(
        error: InvalidPayload,
        message: "Invalid refresh token",
      ))
  }
}

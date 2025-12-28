import auth_server/config.{config}
import auth_server/lib/auth/auth_utils
import auth_server/lib/auth/oauth
import auth_server/lib/auth/transform as auth_transform
import auth_server/lib/user/types.{type User}
import auth_server/lib/utils/api_client
import auth_server/lib/utils/logger
import gleam/http.{Post}
import gleam/http/request
import wisp.{type Request}

pub fn login(req: Request) {
  use <- wisp.require_method(req, Post)
  use json_body <- wisp.require_json(req)

  case auth_transform.login_form_decoder(json_body) {
    Ok(form_data) ->
      case oauth.build_login_response(form_data) {
        Ok(login_response) -> login_response
        Error(error_response) -> error_response
      }
    Error(err) -> {
      logger.log_error(err)
      wisp.json_response("Invalid JSON body", 400)
    }
  }
}

pub fn logout(req: Request, user: User) {
  use <- wisp.require_method(req, Post)

  let site_uri = auth_utils.get_default_admin_url()

  let access_token = auth_utils.get_token(req)

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
    Ok(_) -> wisp.json_response("User logged out", 204)
    Error(wisp_error) -> wisp_error
  }
}

pub fn refresh_token(req: Request) {
  use <- wisp.require_method(req, Post)
  use json_body <- wisp.require_json(req)

  case auth_transform.refresh_token_request_decoder(json_body) {
    Ok(token_request) ->
      case oauth.build_refresh_response(token_request) {
        Ok(token) -> token
        Error(error_response) -> error_response
      }
    Error(_) -> wisp.json_response("Invalid refresh token", 400)
  }
}

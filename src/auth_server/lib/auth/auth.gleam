import auth_server/lib/auth/oauth
import auth_server/lib/auth/transform as auth_transform
import gleam/http.{Post}
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
    Error(_) -> wisp.json_response("Invalid JSON body", 400)
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

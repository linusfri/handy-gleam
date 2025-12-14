import auth_server/auth/auth_utils
import auth_server/auth/oauth
import gleam/http.{Post}
import wisp.{type Request}

pub fn login(req: Request) {
  use <- wisp.require_method(req, Post)
  use json_body <- wisp.require_json(req)

  case auth_utils.login_form_decoder(json_body) {
    Ok(form_data) ->
      case oauth.build_login_response(form_data) {
        Ok(response) -> response
        Error(error_response) -> error_response
      }
    Error(_) -> wisp.json_response("Invalid JSON body", 400)
  }
}

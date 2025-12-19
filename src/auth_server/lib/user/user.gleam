import auth_server/lib/auth/auth_utils
import auth_server/lib/services/user_service
import auth_server/lib/user/transform.{user_decoder, user_encoder}
import auth_server/lib/user/types.{type User}
import gleam/json
import wisp

/// Gets a wisp response containing an encoded user for json response
pub fn to_json(user: User) {
  json.to_string(user_encoder(user))
}

/// Gets a decoded user for use internally.
pub fn get_session_user(req) {
  let token = auth_utils.get_token(req)

  case user_service.request_get_user(token) {
    Ok(user_data) ->
      case user_decoder(user_data) {
        Ok(user) -> Ok(user)

        Error(_) -> Error(wisp.json_response("Failed to decode user", 500))
      }
    Error(wisp_error) -> Error(wisp_error)
  }
}

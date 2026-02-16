import gleam/json
import handygleam/lib/models/auth/auth_utils
import handygleam/lib/models/user/user_transform.{user_encoder}
import handygleam/lib/models/user/user_types.{type User}
import handygleam/lib/services/user_service

/// Gets a wisp response containing an encoded user for json response
pub fn to_json(user: User) {
  json.to_string(user_encoder(user))
}

/// Gets a decoded user for use internally.
pub fn get_session_user(req) {
  let token = auth_utils.get_session_token(req)

  case user_service.request_get_user(token) {
    Ok(user) -> Ok(user)
    Error(wisp_error) -> Error(wisp_error)
  }
}

pub fn get_session_user_by_token(token: String) {
  case user_service.request_get_user(token) {
    Ok(user) -> Ok(user)
    Error(wisp_error) -> Error(wisp_error)
  }
}

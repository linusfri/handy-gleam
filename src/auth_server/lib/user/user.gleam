import auth_server/auth/types
import auth_server/lib/user/encoders.{user_encoder}
import gleam/json

/// Gets a wisp response containing an encoded user for json response
pub fn to_json(user: types.User) {
  json.to_string(user_encoder(user))
}

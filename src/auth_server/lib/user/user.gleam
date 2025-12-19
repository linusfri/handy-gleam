import auth_server/lib/user/transform.{user_encoder}
import auth_server/lib/user/types.{type User}
import gleam/json

/// Gets a wisp response containing an encoded user for json response
pub fn to_json(user: User) {
  json.to_string(user_encoder(user))
}

import auth_server/auth/types.{type User}
import gleam/json

pub fn user_encoder(user: User) -> json.Json {
  json.object([
    #("sub", json.string(user.sub)),
    #("email_verified", json.bool(user.email_verified)),
    #("name", json.string(user.name)),
    #("preferred_username", json.string(user.preferred_username)),
    #("given_name", json.string(user.given_name)),
    #("family_name", json.string(user.family_name)),
    #("email", json.string(user.email)),
  ])
}

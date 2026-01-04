import auth_server/lib/user/types.{type User}
import gleam/http/request
import wisp

pub fn request_short_lived_token(
  req: request.Request(wisp.Connection),
  user: User,
) {
  todo
}

pub fn request_long_lived_token(
  req: request.Request(wisp.Connection),
  user: User,
) {
  todo
}

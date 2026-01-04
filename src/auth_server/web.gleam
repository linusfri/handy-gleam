import auth_server/config.{config}
import auth_server/lib/user/types.{type User}
import auth_server/lib/user/user
import auth_server/lib/utils/logger
import pog
import wisp

pub type Context {
  Context(db: pog.Connection)
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use req <- wisp.csrf_known_header_protection(req)
  use <- wisp.serve_static(
    req,
    under: "/static",
    from: config().static_directory,
  )

  handle_request(req)
}

pub fn authenticated_middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request, User) -> wisp.Response,
) -> wisp.Response {
  case user.get_session_user(req) {
    Ok(user) -> handle_request(req, user)
    Error(wisp_error) -> {
      logger.log_error(wisp_error)
      wisp.json_response(wisp_error, 500)
    }
  }
}

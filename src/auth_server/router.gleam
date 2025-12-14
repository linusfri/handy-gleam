import auth_server/auth/auth
import auth_server/auth/user_service
import auth_server/web
import gleam/http.{Get}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> home_page(req)
    ["auth", "login"] -> auth.login(req)
    ["auth", "user"] -> user_service.get_current_user(req)
    _ -> wisp.json_response("Not found", 404)
  }
}

fn home_page(req: Request) -> Response {
  use <- wisp.require_method(req, Get)

  wisp.ok()
  |> wisp.html_body("App working")
}

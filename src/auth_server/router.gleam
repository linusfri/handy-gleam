import auth_server/auth/auth
import auth_server/services/product_service
import auth_server/services/user_service
import auth_server/web
import gleam/http.{Get}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> home_page(req, ctx)
    ["auth", "login"] -> auth.login(req)
    ["auth", "user"] -> user_service.get_current_user(req, ctx)
    _ -> wisp.json_response("Not found", 404)
  }
}

fn home_page(req: Request, ctx: web.Context) -> Response {
  use <- wisp.require_method(req, Get)

  case product_service.get_products(ctx) {
    Ok(products) -> wisp.json_response(products, 200)
    Error(error) -> wisp.json_response(error, 500)
  }
}

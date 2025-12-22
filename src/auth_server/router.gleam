import auth_server/lib/auth/auth
import auth_server/lib/services/product_service
import auth_server/lib/user/user
import auth_server/web
import gleam/http.{Get, Post}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: web.Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req), req.method {
    [], Get -> home_page(req, ctx)
    ["auth", "login"], Post -> auth.login(req)
    ["auth", "refresh-token"], Post -> auth.refresh_token(req)
    ["auth", "user"], method -> {
      use _, user <- web.authenticated_middleware(req)
      case method {
        Get -> wisp.json_response(user.to_json(user), 200)
        Post -> wisp.json_response("Create user", 201)
        _ -> wisp.method_not_allowed(allowed: [Get, Post])
      }
    }
    ["products"], method -> {
      use req, user <- web.authenticated_middleware(req)

      case method {
        Get -> product_service.get_products(ctx, user)
        Post -> product_service.create_product(req, ctx, user)
        _ -> wisp.not_found()
      }
    }
    _, _ -> wisp.json_response("Not found", 404)
  }
}

fn home_page(req: Request, _: web.Context) -> Response {
  use <- wisp.require_method(req, Get)
  wisp.json_response("Ping", 200)
}

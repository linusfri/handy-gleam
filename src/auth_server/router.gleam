import auth_server/global_types
import auth_server/lib/models/auth/auth
import auth_server/lib/models/user/user
import auth_server/lib/services/file_service
import auth_server/lib/services/integration_service
import auth_server/lib/services/product_service
import auth_server/sql
import auth_server/web
import gleam/http.{Delete, Get, Post, Put}
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: global_types.Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req), req.method {
    [], Get -> home_page(req, ctx)
    ["auth", "login"], Post -> auth.login(req)
    ["auth", "logout"], Post -> {
      use _, user <- web.authenticated_middleware(req)
      auth.logout(req, user)
    }
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
        _ -> wisp.method_not_allowed(allowed: [Get, Post])
      }
    }
    ["products", product_id], method -> {
      use req, user <- web.authenticated_middleware(req)
      case method {
        Get -> product_service.get_product(req, ctx, user, product_id)
        Put -> product_service.update_product(req, ctx, user, product_id)
        Delete -> product_service.delete_product(req, ctx, user, product_id)
        _ -> wisp.method_not_allowed(allowed: [Get, Delete])
      }
    }
    ["files"], method -> {
      use req, user <- web.authenticated_middleware(req)
      case method {
        Get -> file_service.get_files(req, ctx, user)
        Post -> file_service.create_files(req, ctx, user)
        _ -> wisp.method_not_allowed(allowed: [Delete])
      }
    }
    ["files", image_id], method -> {
      use req, user <- web.authenticated_middleware(req)
      case method {
        Delete -> file_service.delete_file(req, ctx, user, image_id)
        _ -> wisp.method_not_allowed(allowed: [Delete])
      }
    }
    ["facebook-instagram", "login"], method -> {
      use req, _ <- web.authenticated_middleware(req)
      case method {
        Get -> integration_service.initiate_facebook_login(req)
        _ -> wisp.method_not_allowed(allowed: [Get])
      }
    }
    ["facebook-instagram", "long-lived-token"], method -> {
      case method {
        Get -> integration_service.request_long_lived_facebook_token(req, ctx)
        _ -> wisp.method_not_allowed(allowed: [Get])
      }
    }
    ["facebook-instagram", "user"], method -> {
      use _, user <- web.authenticated_middleware(req)
      case method {
        Get -> integration_service.get_facebook_user(ctx, user, sql.Facebook)
        _ -> wisp.method_not_allowed(allowed: [Get])
      }
    }
    _, _ -> wisp.json_response("Not found", 404)
  }
}

fn home_page(req: Request, _: global_types.Context) -> Response {
  use <- wisp.require_method(req, Get)
  wisp.json_response("Ping", 200)
}

import auth_server/auth/auth
import auth_server/auth/user_service
import auth_server/sql
import auth_server/web
import gleam/http.{Get}
import gleam/json
import gleam/list
import gleam/option
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

  case sql.select_products(ctx.db) {
    Ok(products) -> {
      let products_json =
        products.rows
        |> list.map(encode_product)
        |> json.array(of: fn(x) { x })

      wisp.json_response(json.to_string(products_json), 200)
    }
    Error(err) -> {
      wisp.json_response("{\"error\": \"Database error\"}", 500)
    }
  }
}

fn encode_product(product: sql.SelectProductsRow) -> json.Json {
  json.object([
    #("id", json.int(product.id)),
    #("name", json.string(product.name)),
    #(
      "description",
      product.description
        |> option.map(json.string)
        |> option.unwrap(json.null()),
    ),
  ])
}

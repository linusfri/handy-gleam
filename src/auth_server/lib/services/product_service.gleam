import auth_server/lib/product/product.{select_products_row_to_json}
import auth_server/lib/user/types.{type User}
import auth_server/sql
import auth_server/web
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import wisp

pub fn get_products(ctx: web.Context, user: User) {
  case sql.select_products(ctx.db, user.groups) {
    Ok(products) -> {
      let products_json =
        products.rows
        |> list.map(select_products_row_to_json)
        |> json.array(of: fn(x) { x })

      wisp.json_response(json.to_string(products_json), 200)
    }
    Error(error) -> wisp.json_response(string.inspect(error), 500)
  }
}

pub fn create_product(
  req: request.Request(wisp.Connection),
  ctx: web.Context,
  user: User,
) {
  use <- wisp.require_method(req, http.Post)
  use json_body <- wisp.require_json(req)

  case product.create_product(data: json_body, context: ctx, user: user) {
    Ok(_) -> wisp.json_response("Product created", 201)
    Error(err) -> wisp.json_response(err, 500)
  }
}

pub fn delete_product(
  req: request.Request(wisp.Connection),
  ctx: web.Context,
  user: User,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)
  let query_parameters = wisp.get_query(req)

  let delete_product_result = {
    use product_id_str <- result.try(
      list.key_find(query_parameters, "product_id")
      |> result.replace_error("No product id provided"),
    )

    use product_id <- result.try(
      int.parse(product_id_str)
      |> result.replace_error("Invalid product id"),
    )

    product.delete_product(product_id: product_id, context: ctx, user: user)
  }

  case delete_product_result {
    Ok(_) -> wisp.json_response("Product deleted successfully", 200)
    Error("No product id provided") ->
      wisp.json_response("No product id provided", 400)
    Error("Invalid product id") -> wisp.json_response("Invalid product id", 400)
    Error(err) -> wisp.json_response(err, 500)
  }
}

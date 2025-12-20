import auth_server/lib/product/product.{select_products_row_to_json}
import auth_server/sql
import auth_server/web
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option
import wisp

pub fn get_products(ctx: web.Context) {
  case sql.select_products(ctx.db) {
    Ok(products) -> {
      let products_json =
        products.rows
        |> list.map(select_products_row_to_json)
        |> json.array(of: fn(x) { x })

      Ok(json.to_string(products_json))
    }
    Error(_) -> {
      Error("{\"error\": \"Could not get products\"}")
    }
  }
}

pub fn create_product(req: request.Request(wisp.Connection), ctx: web.Context) {
  use <- wisp.require_method(req, http.Post)
  use json_body <- wisp.require_json(req)

  case product.product_decoder(json_body) {
    Ok(product) ->
      case
        sql.create_product(
          ctx.db,
          product.name,
          option.unwrap(product.description, ""),
          product.status,
          product.price,
        )
      {
        Ok(_) -> wisp.json_response("Created", 201)
        Error(_) -> wisp.json_response("Could not create product", 500)
      }
    Error(_) -> wisp.json_response("Could not decode product", 400)
  }
}

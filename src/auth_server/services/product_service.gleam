import auth_server/sql
import auth_server/web
import gleam/json
import gleam/list
import gleam/option

pub fn get_products(ctx: web.Context) {
  case sql.select_products(ctx.db) {
    Ok(products) -> {
      let products_json =
        products.rows
        |> list.map(encode_product)
        |> json.array(of: fn(x) { x })

      Ok(json.to_string(products_json))
    }
    Error(_) -> {
      Error("{\"error\": \"Could not get products\"}")
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

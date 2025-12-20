import auth_server/lib/product/product.{select_products_row_to_json}
import auth_server/sql
import auth_server/web
import gleam/json
import gleam/list

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

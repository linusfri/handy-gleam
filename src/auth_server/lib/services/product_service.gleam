import auth_server/sql
import auth_server/web
import gleam/json
import gleam/list
import gleam/option
import gleam/time/timestamp

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

fn select_products_row_to_json(
  select_products_row: sql.SelectProductsRow,
) -> json.Json {
  let sql.SelectProductsRow(id:, name:, description:, created_at:, updated_at:) =
    select_products_row
  json.object([
    #("id", json.int(id)),
    #("name", json.string(name)),
    #("description", case description {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("created_at", case created_at {
      option.None -> json.null()
      option.Some(time) -> json.float(timestamp.to_unix_seconds(time))
    }),
    #("updated_at", case updated_at {
      option.None -> json.null()
      option.Some(time) -> {
        json.float(timestamp.to_unix_seconds(time))
      }
    }),
  ])
}

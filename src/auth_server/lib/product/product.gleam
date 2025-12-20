import auth_server/sql.{
  type ProductStatus, type SelectProductsRow, Available, SelectProductsRow, Sold,
}
import gleam/json
import gleam/option
import gleam/time/timestamp

pub fn select_products_row_to_json(
  select_products_row: SelectProductsRow,
) -> json.Json {
  let SelectProductsRow(
    id:,
    name:,
    description:,
    status:,
    price:,
    created_at:,
    updated_at:,
  ) = select_products_row
  json.object([
    #("id", json.int(id)),
    #("name", json.string(name)),
    #("description", case description {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("status", product_status_to_json(status)),
    #("price", json.float(price)),
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

pub fn product_status_to_json(product_status: ProductStatus) -> json.Json {
  case product_status {
    Available -> json.string("available")
    Sold -> json.string("sold")
  }
}

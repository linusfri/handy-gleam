import auth_server/sql.{
  type ProductStatus, type SelectProductsRow, Available, SelectProductsRow, Sold,
}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/time/timestamp
import pog

pub type CreateProductRow {
  CreateProductRow(
    name: String,
    description: Option(String),
    status: ProductStatus,
    price: Float,
    image: Option(String),
  )
}

fn product_status_decoder() -> decode.Decoder(ProductStatus) {
  use product_status <- decode.then(decode.string)
  case product_status {
    "available" -> decode.success(Available)
    "sold" -> decode.success(Sold)
    _ -> decode.failure(Available, "ProductStatus")
  }
}

/// This is for allowing both ints and floats to be sent from a client
fn product_price_decoder() -> decode.Decoder(Float) {
  decode.one_of(decode.float, [decode.int |> decode.map(int.to_float)])
}

fn product_status_to_json(product_status: ProductStatus) -> json.Json {
  case product_status {
    Available -> json.string("available")
    Sold -> json.string("sold")
  }
}

pub fn create_product_row_decoder(product_data_create: Dynamic) {
  let products_row_decoder = {
    use name <- decode.field("name", decode.string)
    use description <- decode.field(
      "description",
      decode.optional(decode.string),
    )
    use status <- decode.field("status", product_status_decoder())
    use price <- decode.field("price", product_price_decoder())
    use image <- decode.field("image", decode.optional(decode.string))
    decode.success(CreateProductRow(
      name:,
      description:,
      status:,
      price:,
      image:,
    ))
  }

  decode.run(product_data_create, products_row_decoder)
}

pub fn select_product_row_decoder(product_data_select: Dynamic) {
  let products_row_decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    use description <- decode.field(
      "description",
      decode.optional(decode.string),
    )
    use status <- decode.field("status", product_status_decoder())
    use price <- decode.field("price", decode.float)
    use created_at <- decode.field(
      "created_at",
      decode.optional(pog.timestamp_decoder()),
    )
    use updated_at <- decode.field(
      "updated_at",
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(SelectProductsRow(
      id:,
      name:,
      description:,
      status:,
      price:,
      created_at:,
      updated_at:,
    ))
  }

  decode.run(product_data_select, products_row_decoder)
}

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

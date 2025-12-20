//// This module contains the code to run the sql queries defined in
//// `./src/auth_server/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog

/// A row you get from running the `select_products` query
/// defined in `./src/auth_server/sql/select_products.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SelectProductsRow {
  SelectProductsRow(
    id: Int,
    name: String,
    description: Option(String),
    status: ProductStatus,
    price: Float,
    created_at: Option(Timestamp),
    updated_at: Option(Timestamp),
  )
}

/// Runs the `select_products` query
/// defined in `./src/auth_server/sql/select_products.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_products(
  db: pog.Connection,
) -> Result(pog.Returned(SelectProductsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.optional(decode.string))
    use status <- decode.field(3, product_status_decoder())
    use price <- decode.field(4, pog.numeric_decoder())
    use created_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
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

  "select * from products;"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Enums -------------------------------------------------------------------

/// Corresponds to the Postgres `product_status` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ProductStatus {
  Available
  Sold
}

fn product_status_decoder() -> decode.Decoder(ProductStatus) {
  use product_status <- decode.then(decode.string)
  case product_status {
    "available" -> decode.success(Available)
    "sold" -> decode.success(Sold)
    _ -> decode.failure(Available, "ProductStatus")
  }
}

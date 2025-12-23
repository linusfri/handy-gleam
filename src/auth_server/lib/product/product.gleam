import auth_server/lib/file_handlers/file_handler
import auth_server/lib/user/types.{type User}
import auth_server/sql.{
  type ProductStatus, type SelectProductsRow, Available, SelectProductsRow, Sold,
}
import auth_server/web
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/time/timestamp
import pog

pub type CreateProductRequest {
  CreateProductRequest(
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
    decode.success(CreateProductRequest(
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
    use images <- decode.field("images", decode.list(decode.string))
    echo images
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
      images:,
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
    images:,
    created_at:,
    updated_at:,
  ) = select_products_row
  json.object([
    #("id", json.int(id)),
    #("name", json.string(name)),
    #(
      "images",
      json.array(images, fn(filename) {
        json.string(file_handler.file_url(filename, "images/products"))
      }),
    ),
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

/// Creates an image if base64 string is provided
pub fn create_product_image(
  ctx ctx: web.Context,
  create_product_request create_product_request: CreateProductRequest,
  product_id product_id: Int,
) -> Result(String, String) {
  let product_image_result =
    file_handler.create_file(
      filename: create_product_request.name,
      base64_encoded_file: create_product_request.image,
      directory: "images/products",
    )

  use product_image_name <- result.try(product_image_result)

  // If no image, return empty string
  case product_image_name {
    "" -> Ok("")
    _ -> {
      use created_image_row <- result.try(
        sql.create_image(ctx.db, product_image_name)
        |> result.map_error(fn(err) {
          "Failed to create image: " <> string.inspect(err)
        }),
      )

      // Extract the image ID from the first row
      case created_image_row.rows {
        [first_image, ..] -> {
          use _ <- result.try(
            // Last argument is order
            sql.create_product_image(ctx.db, product_id, first_image.id, 0)
            |> result.map_error(fn(err) {
              "Failed to link product image: " <> string.inspect(err)
            }),
          )
          Ok(product_image_name)
        }
        [] -> Error("No image ID returned from database")
      }
    }
  }
}

pub fn create_product(
  data data: Dynamic,
  user user: User,
  context ctx: web.Context,
) -> Result(Nil, String) {
  // First creates the product
  use product_request <- result.try(
    create_product_row_decoder(data)
    |> result.map_error(fn(errors) { string.inspect(errors) }),
  )

  use create_product_response <- result.try(
    sql.create_product(
      ctx.db,
      product_request.name,
      option.unwrap(product_request.description, ""),
      product_request.status,
      product_request.price,
    )
    |> result.map_error(fn(_) { "Could not create product" }),
  )

  // Get the first product ID from the created product
  use first_product <- result.try(case create_product_response.rows {
    [first, ..] -> Ok(first)
    [] -> Error("No product ID returned from db query")
  })

  use _path <- result.try(
    create_product_image(ctx, product_request, first_product.id)
    |> result.map_error(fn(err) { "Image upload failed: " <> err }),
  )

  // Then connects the created product to the groups the user is part of
  let product_ids = list.map(create_product_response.rows, fn(row) { row.id })
  use _ <- result.try(
    sql.create_products_user_groups(ctx.db, product_ids, user.groups)
    |> result.map_error(fn(err) { string.inspect(err) }),
  )

  Ok(Nil)
}

pub fn delete_product(
  product_id product_id: Int,
  context ctx: web.Context,
  user user: User,
) -> Result(Nil, String) {
  use _ <- result.try(
    sql.delete_product(ctx.db, product_id, user.groups)
    |> result.map_error(fn(err) {
      "Failed to delete product: " <> string.inspect(err)
    }),
  )

  Ok(Nil)
}

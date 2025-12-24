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
    images: List(String),
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
    use images <- decode.field("images", decode.list(decode.string))
    decode.success(CreateProductRequest(
      name:,
      description:,
      status:,
      price:,
      images:,
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

fn create_product_images_files(product_name: String, images: List(String)) {
  let valid_images = list.filter(images, fn(img) { img != "" })

  case valid_images {
    [] -> Ok([])
    _ -> {
      list.map(valid_images, fn(base64_image) {
        file_handler.create_file(
          filename: product_name,
          base64_encoded_file: base64_image,
          directory: "images/products",
        )
      })
      |> result.all()
    }
  }
}

fn create_product_images_in_db(
  ctx: web.Context,
  product_id: Int,
  filenames: List(String),
) {
  case filenames {
    [] -> Ok([])
    _ -> {
      // Create all image records in database
      use created_images <- result.try(
        sql.create_images(ctx.db, filenames)
        |> result.map_error(fn(err) {
          "Failed to create images: " <> string.inspect(err)
        }),
      )

      // Link all images to the product
      let image_ids = list.map(created_images.rows, fn(row) { row.id })
      use _ <- result.try(
        sql.create_product_images(ctx.db, product_id, image_ids)
        |> result.map_error(fn(err) {
          "Failed to link product images: " <> string.inspect(err)
        }),
      )

      Ok(filenames)
    }
  }
}

/// Creates images if base64 string is provided
pub fn create_product_images(
  ctx ctx: web.Context,
  product_name product_name: String,
  images images: List(String),
  product_id product_id: Int,
) -> Result(List(String), String) {
  // Filter out empty strings
  let valid_filenames = list.filter(images, fn(name) { name != "" })

  use _ <- result.try(create_product_images_files(product_name, valid_filenames))

  create_product_images_in_db(ctx, product_id, valid_filenames)
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
    create_product_images(
      ctx,
      product_request.name,
      product_request.images,
      first_product.id,
    )
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

pub fn get_product_by_id(
  product_id product_id: Int,
  context ctx: web.Context,
  user user: User,
) -> Result(SelectProductsRow, String) {
  use product_result <- result.try(
    sql.select_product_by_id(ctx.db, product_id, user.groups)
    |> result.map_error(fn(err) {
      "Failed to get product: " <> string.inspect(err)
    }),
  )

  // Extract the product from the first row and convert to SelectProductsRow
  case product_result.rows {
    [product, ..] ->
      Ok(SelectProductsRow(
        id: product.id,
        name: product.name,
        description: product.description,
        status: product.status,
        price: product.price,
        images: product.images,
        created_at: product.created_at,
        updated_at: product.updated_at,
      ))
    [] -> Error("Product not found or access denied")
  }
}

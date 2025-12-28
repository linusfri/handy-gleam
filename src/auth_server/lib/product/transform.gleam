import auth_server/lib/file/transform as file_transform
import auth_server/lib/file/types.{type File, type FileType, File}
import auth_server/lib/file_system/file_system
import auth_server/sql.{type ProductStatus, Available, Sold}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/time/timestamp
import pog

pub type State {
  Existing
  New
}

pub type Product {
  Product(
    id: Int,
    name: String,
    description: Option(String),
    status: ProductStatus,
    price: Float,
    images: List(File),
    created_at: Option(timestamp.Timestamp),
    updated_at: Option(timestamp.Timestamp),
  )
}

/// Could be something that only contains kind and id. Or it could contain kind and all of the other keys except id.
pub type CreateProductImageRequest {
  CreateProductImageRequest(
    kind: State,
    id: Option(Int),
    data: Option(String),
    filename: Option(String),
    mimetype: Option(FileType),
  )
}

pub type CreateProductRequest {
  CreateProductRequest(
    name: String,
    description: Option(String),
    status: ProductStatus,
    price: Float,
    images: List(CreateProductImageRequest),
  )
}

fn product_image_response_decoder() -> decode.Decoder(File) {
  use id <- decode.field("id", decode.int)
  use filename <- decode.field("filename", decode.string)
  use file_type <- decode.field("file_type", file_transform.file_type_decoder())
  use context_type <- decode.field("context_type", context_type_decoder())

  decode.success(File(
    id: option.Some(id),
    data: option.None,
    filename:,
    context_type:,
    file_type:,
    uri: option.Some(file_system.file_url(filename, context_type, file_type)),
  ))
}

fn context_type_decoder() -> decode.Decoder(sql.ContextTypeEnum) {
  use value <- decode.then(decode.string)
  case value {
    "product" -> decode.success(sql.Product)
    "user" -> decode.success(sql.User)
    "misc" -> decode.success(sql.Misc)
    _ -> decode.failure(sql.Misc, "ContextTypeEnum")
  }
}

fn product_image_request_decoder() -> decode.Decoder(CreateProductImageRequest) {
  use kind_str <- decode.field("kind", decode.string)
  use id <- decode.optional_field(
    "id",
    option.None,
    decode.optional(decode.int),
  )
  use data <- decode.optional_field(
    "data",
    option.None,
    decode.optional(decode.string),
  )
  use filename <- decode.optional_field(
    "filename",
    option.None,
    decode.optional(decode.string),
  )
  use mimetype <- decode.optional_field(
    "mimetype",
    option.None,
    decode.optional(file_transform.file_type_decoder()),
  )

  let kind = case kind_str {
    "new" -> New
    "existing" -> Existing
    _ -> New
  }

  decode.success(CreateProductImageRequest(
    kind:,
    id:,
    data:,
    filename:,
    mimetype:,
  ))
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

pub fn create_product_request_decoder(product_data_create: Dynamic) {
  let products_row_decoder = {
    use name <- decode.field("name", decode.string)
    use description <- decode.field(
      "description",
      decode.optional(decode.string),
    )
    use status <- decode.field("status", product_status_decoder())
    use price <- decode.field("price", product_price_decoder())
    use images <- decode.field(
      "images",
      decode.list(product_image_request_decoder()),
    )
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

pub fn product_decoder(product_data: Dynamic) {
  let product_decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    use description <- decode.field(
      "description",
      decode.optional(decode.string),
    )
    use status <- decode.field("status", product_status_decoder())
    use price <- decode.field("price", decode.float)
    use images <- decode.field(
      "images",
      decode.list(product_image_response_decoder()),
    )
    use created_at <- decode.field(
      "created_at",
      decode.optional(pog.timestamp_decoder()),
    )
    use updated_at <- decode.field(
      "updated_at",
      decode.optional(pog.timestamp_decoder()),
    )
    decode.success(Product(
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

  decode.run(product_data, product_decoder)
}

pub fn product_to_json(product_to_json: sql.SelectProductsRow) -> json.Json {
  let sql.SelectProductsRow(
    id:,
    name:,
    description:,
    status:,
    price:,
    images:,
    created_at:,
    updated_at:,
  ) = product_to_json
  let images =
    json.parse(images, decode.list(product_image_response_decoder()))
    |> result.unwrap([])

  json.object([
    #("id", json.int(id)),
    #("name", json.string(name)),
    #(
      "images",
      json.array(images, fn(image) {
        json.object([
          #("id", json.nullable(image.id, of: json.int)),
          #("filename", json.string(image.filename)),
          #("file_type", file_transform.file_type_enum_to_json(image.file_type)),
          #(
            "context_type",
            file_transform.context_type_enum_to_json(image.context_type),
          ),
          #("uri", json.nullable(image.uri, of: json.string)),
          #("data", json.nullable(image.data, of: json.string)),
        ])
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

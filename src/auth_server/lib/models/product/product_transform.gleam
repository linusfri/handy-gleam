import auth_server/lib/models/file/file_transform
import auth_server/lib/models/file/file_types.{type File, File}
import auth_server/lib/models/file_system/file_system
import auth_server/lib/models/product/product_types
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
    integrations: List(ProductIntegration),
    created_at: Option(timestamp.Timestamp),
    updated_at: Option(timestamp.Timestamp),
  )
}

pub type ProductIntegration {
  ProductIntegration(
    platform: sql.IntegrationPlatform,
    resource_id: String,
    resource_type: sql.ResourceTypeEnum,
  )
}

pub type ProductMutationRequest {
  ProductMutationRequest(
    name: String,
    description: Option(String),
    status: ProductStatus,
    price: Float,
    image_ids: List(Int),
    integrations: List(ProductIntegration),
  )
}

pub fn resource_type_enum_decoder() -> decode.Decoder(sql.ResourceTypeEnum) {
  use resource_type_enum <- decode.then(decode.string)
  case resource_type_enum {
    "page" -> decode.success(sql.Page)
    _ -> decode.failure(sql.Page, "ResourceTypeEnum")
  }
}

pub fn update_product_row_to_facebook_product(
  update_product_row: sql.UpdateProductRow,
) {
  product_types.FacebookProduct(
    id: update_product_row.id,
    name: update_product_row.name,
    description: update_product_row.description,
    status: update_product_row.status,
    price: update_product_row.price,
    images: parse_product_images_json(update_product_row.images),
  )
}

pub fn create_product_row_to_facebook_product(
  create_product_row: sql.CreateProductRow,
) {
  product_types.FacebookProduct(
    id: create_product_row.id,
    name: create_product_row.name,
    description: create_product_row.description,
    status: create_product_row.status,
    price: create_product_row.price,
    images: parse_product_images_json(create_product_row.images),
  )
}

fn product_image_response_decoder() -> decode.Decoder(File) {
  use id <- decode.field("id", decode.int)
  use filename <- decode.field("filename", decode.string)
  use file_type <- decode.field("file_type", file_transform.file_type_decoder())
  use context_type <- decode.field(
    "context_type",
    file_transform.context_type_decoder(),
  )

  decode.success(File(
    id: option.Some(id),
    data: option.None,
    filename:,
    context_type:,
    file_type:,
    uri: option.Some(file_system.file_url(filename, context_type, file_type)),
  ))
}

pub fn parse_product_images_json(images_json: String) -> List(File) {
  json.parse(images_json, decode.list(product_image_response_decoder()))
  |> result.unwrap([])
}

pub fn parse_product_integrations_json(
  integrations_json: String,
) -> List(ProductIntegration) {
  json.parse(integrations_json, decode.list(product_integration_decoder()))
  |> result.unwrap([])
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

fn integration_platform_to_json(platform: sql.IntegrationPlatform) -> json.Json {
  case platform {
    sql.Facebook -> json.string("facebook")
    sql.Instagram -> json.string("instagram")
  }
}

fn integration_platform_decoder() -> decode.Decoder(sql.IntegrationPlatform) {
  use integration_platform <- decode.then(decode.string)
  case integration_platform {
    "facebook" -> decode.success(sql.Facebook)
    "instagram" -> decode.success(sql.Instagram)
    _ -> decode.failure(sql.Facebook, "IntegrationPlatform")
  }
}

fn product_integration_decoder() -> decode.Decoder(ProductIntegration) {
  use platform <- decode.field("platform", integration_platform_decoder())
  use resource_id <- decode.field("resource_id", decode.string)
  use resource_type <- decode.field(
    "resource_type",
    resource_type_enum_decoder(),
  )

  decode.success(ProductIntegration(platform:, resource_id:, resource_type:))
}

/// For both product update and create
pub fn product_mutation_request_decoder(product_data_create: Dynamic) {
  let products_row_decoder = {
    use name <- decode.field("name", decode.string)
    use description <- decode.field(
      "description",
      decode.optional(decode.string),
    )
    use status <- decode.field("status", product_status_decoder())
    use price <- decode.field("price", product_price_decoder())
    use image_ids <- decode.field("image_ids", decode.list(decode.int))
    use integrations <- decode.optional_field(
      "integrations",
      [],
      decode.list(product_integration_decoder()),
    )
    decode.success(ProductMutationRequest(
      name:,
      description:,
      status:,
      price:,
      image_ids:,
      integrations:,
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
    use integrations <- decode.field(
      "integrations",
      decode.list(product_integration_decoder()),
    )
    decode.success(Product(
      id:,
      name:,
      description:,
      status:,
      price:,
      images:,
      integrations:,
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
    integrations:,
    created_at:,
    updated_at:,
  ) = product_to_json
  let images =
    json.parse(images, decode.list(product_image_response_decoder()))
    |> result.unwrap([])
  let integrations_list =
    json.parse(integrations, decode.list(product_integration_decoder()))
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
    #(
      "integrations",
      json.array(integrations_list, fn(integration) {
        json.object([
          #("platform", integration_platform_to_json(integration.platform)),
          #("resource_id", json.string(integration.resource_id)),
        ])
      }),
    ),
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

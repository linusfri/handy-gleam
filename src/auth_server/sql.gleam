//// This module contains the code to run the sql queries defined in
//// `./src/auth_server/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog

/// A row you get from running the `create_images` query
/// defined in `./src/auth_server/sql/create_images.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateImagesRow {
  CreateImagesRow(id: Int, filename: String)
}

/// Runs the `create_images` query
/// defined in `./src/auth_server/sql/create_images.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_images(
  db: pog.Connection,
  arg_1: List(String),
) -> Result(pog.Returned(CreateImagesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use filename <- decode.field(1, decode.string)
    decode.success(CreateImagesRow(id:, filename:))
  }

  "insert into images (filename, created_at)
select unnest($1::text[]), now()
returning id, filename;"
  |> pog.query
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_product` query
/// defined in `./src/auth_server/sql/create_product.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateProductRow {
  CreateProductRow(
    id: Int,
    name: String,
    description: Option(String),
    status: ProductStatus,
    price: Float,
    created_at: Option(Timestamp),
    updated_at: Option(Timestamp),
  )
}

/// Runs the `create_product` query
/// defined in `./src/auth_server/sql/create_product.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_product(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: ProductStatus,
  arg_4: Float,
) -> Result(pog.Returned(CreateProductRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.optional(decode.string))
    use status <- decode.field(3, product_status_decoder())
    use price <- decode.field(4, pog.numeric_decoder())
    use created_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    decode.success(CreateProductRow(
      id:,
      name:,
      description:,
      status:,
      price:,
      created_at:,
      updated_at:,
    ))
  }

  "insert into products (name, description, status, price, created_at, updated_at) values
    ($1, $2, $3, $4, now(), now()) returning *;"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(product_status_encoder(arg_3))
  |> pog.parameter(pog.float(arg_4))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `create_product_images` query
/// defined in `./src/auth_server/sql/create_product_images.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_product_images(
  db: pog.Connection,
  arg_1: Int,
  arg_2: List(Int),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "insert into product_image (product_id, image_id, display_order)
select $1, image_id, row_number() over () - 1
from unnest($2::int[]) as image_id;"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.array(fn(value) { pog.int(value) }, arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `create_product_user_group` query
/// defined in `./src/auth_server/sql/create_product_user_group.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_product_user_group(
  db: pog.Connection,
  arg_1: Int,
  arg_2: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "insert into product_user_group (product_id, user_group_id, created_at)
values ($1, $2, now());"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `create_products_user_groups` query
/// defined in `./src/auth_server/sql/create_products_user_groups.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_products_user_groups(
  db: pog.Connection,
  arg_1: List(Int),
  arg_2: List(String),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "insert into product_user_group (product_id, user_group_id, created_at)
select p.product_id, g.user_group_id, now()
from unnest($1::int[]) as p(product_id)
cross join unnest($2::text[]) as g(user_group_id);"
  |> pog.query
  |> pog.parameter(pog.array(fn(value) { pog.int(value) }, arg_1))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// name: delete_image_by_id
/// Deletes an image only if it belongs to a product in user's groups
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_image_by_id(
  db: pog.Connection,
  arg_1: Int,
  arg_2: List(String),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- name: delete_image_by_id
-- Deletes an image only if it belongs to a product in user's groups
delete from images i
where i.id = $1
and exists (
  select 1 from product_image pi
  inner join product_user_group pug on pi.product_id = pug.product_id
  where pi.image_id = i.id
  and pug.user_group_id = any($2)
);"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// name: delete_product
/// Deletes a product by ID only if it belongs to user's groups
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_product(
  db: pog.Connection,
  arg_1: Int,
  arg_2: List(String),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- name: delete_product
-- Deletes a product by ID only if it belongs to user's groups
delete from products p
where p.id = $1
and exists (
  select 1 from product_user_group pug
  where pug.product_id = p.id
  and pug.user_group_id = any($2)
);
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `select_image_by_id` query
/// defined in `./src/auth_server/sql/select_image_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SelectImageByIdRow {
  SelectImageByIdRow(id: Int, filename: String, created_at: Option(Timestamp))
}

/// name: select_image_by_id
/// Get image details by ID
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_image_by_id(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(SelectImageByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use filename <- decode.field(1, decode.string)
    use created_at <- decode.field(2, decode.optional(pog.timestamp_decoder()))
    decode.success(SelectImageByIdRow(id:, filename:, created_at:))
  }

  "-- name: select_image_by_id
-- Get image details by ID
select id, filename, created_at
from images
where id = $1;"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `select_product_by_id` query
/// defined in `./src/auth_server/sql/select_product_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SelectProductByIdRow {
  SelectProductByIdRow(
    id: Int,
    name: String,
    description: Option(String),
    status: ProductStatus,
    price: Float,
    created_at: Option(Timestamp),
    updated_at: Option(Timestamp),
    images: List(String),
  )
}

/// name: select_product_by_id
/// Select a product by ID only if it belongs to user's groups
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_product_by_id(
  db: pog.Connection,
  arg_1: Int,
  arg_2: List(String),
) -> Result(pog.Returned(SelectProductByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.optional(decode.string))
    use status <- decode.field(3, product_status_decoder())
    use price <- decode.field(4, pog.numeric_decoder())
    use created_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    use images <- decode.field(7, decode.list(decode.string))
    decode.success(SelectProductByIdRow(
      id:,
      name:,
      description:,
      status:,
      price:,
      created_at:,
      updated_at:,
      images:,
    ))
  }

  "-- name: select_product_by_id
-- Select a product by ID only if it belongs to user's groups
select 
  products.id,
  products.name,
  products.description,
  products.status,
  products.price,
  products.created_at,
  products.updated_at,
  COALESCE(array_agg(images.filename) filter (where images.filename is not null), '{}') as images
from products
inner join product_user_group on products.id = product_user_group.product_id
left join product_image on products.id = product_image.product_id
left join images on product_image.image_id = images.id
where products.id = $1
and product_user_group.user_group_id = any($2)
group by products.id, products.name, products.description, products.status, products.price, products.created_at, products.updated_at
limit 1;"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

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
    images: List(String),
  )
}

/// select_products.sql
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_products(
  db: pog.Connection,
  arg_1: List(String),
) -> Result(pog.Returned(SelectProductsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.optional(decode.string))
    use status <- decode.field(3, product_status_decoder())
    use price <- decode.field(4, pog.numeric_decoder())
    use created_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    use images <- decode.field(7, decode.list(decode.string))
    decode.success(SelectProductsRow(
      id:,
      name:,
      description:,
      status:,
      price:,
      created_at:,
      updated_at:,
      images:,
    ))
  }

  "-- select_products.sql
select 
  products.id,
  products.name,
  products.description,
  products.status,
  products.price,
  products.created_at,
  products.updated_at,
  COALESCE(array_agg(images.filename) filter (where images.filename is not null), '{}') as images
from products
inner join product_user_group on products.id = product_user_group.product_id
left join product_image on products.id = product_image.product_id
left join images on product_image.image_id = images.id
where product_user_group.user_group_id = any($1)
group by products.id, products.name, products.description, products.status, products.price, products.created_at, products.updated_at
order by products.id;"
  |> pog.query
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_1))
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

fn product_status_encoder(product_status) -> pog.Value {
  case product_status {
    Available -> "available"
    Sold -> "sold"
  }
  |> pog.text
}

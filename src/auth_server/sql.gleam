//// This module contains the code to run the sql queries defined in
//// `./src/auth_server/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog

/// A row you get from running the `create_files` query
/// defined in `./src/auth_server/sql/create_files.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateFilesRow {
  CreateFilesRow(
    id: Int,
    filename: String,
    file_type: FileTypeEnum,
    context_type: ContextTypeEnum,
  )
}

/// Runs the `create_files` query
/// defined in `./src/auth_server/sql/create_files.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_files(
  db: pog.Connection,
  arg_1: List(String),
  arg_2: List(FileTypeEnum),
  arg_3: List(ContextTypeEnum),
) -> Result(pog.Returned(CreateFilesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use filename <- decode.field(1, decode.string)
    use file_type <- decode.field(2, file_type_enum_decoder())
    use context_type <- decode.field(3, context_type_enum_decoder())
    decode.success(CreateFilesRow(id:, filename:, file_type:, context_type:))
  }

  "insert into files (filename, file_type, context_type)
select * from unnest(
  $1::text[],              -- filenames
  $2::file_type_enum[],    -- file_types (MIME types)
  $3::context_type_enum[]  -- context_types context_type_enum 
)
returning id, filename, file_type, context_type;"
  |> pog.query
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_1))
  |> pog.parameter(
    pog.array(fn(value) { file_type_enum_encoder(value) }, arg_2),
  )
  |> pog.parameter(
    pog.array(fn(value) { context_type_enum_encoder(value) }, arg_3),
  )
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_files_user_groups` query
/// defined in `./src/auth_server/sql/create_files_user_groups.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateFilesUserGroupsRow {
  CreateFilesUserGroupsRow(
    id: Int,
    file_id: Int,
    user_group_id: String,
    created_at: Option(Timestamp),
  )
}

/// Runs the `create_files_user_groups` query
/// defined in `./src/auth_server/sql/create_files_user_groups.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_files_user_groups(
  db: pog.Connection,
  arg_1: List(Int),
  arg_2: List(String),
) -> Result(pog.Returned(CreateFilesUserGroupsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use file_id <- decode.field(1, decode.int)
    use user_group_id <- decode.field(2, decode.string)
    use created_at <- decode.field(3, decode.optional(pog.timestamp_decoder()))
    decode.success(CreateFilesUserGroupsRow(
      id:,
      file_id:,
      user_group_id:,
      created_at:,
    ))
  }

  "insert into
  file_user_group (file_id, user_group_id)
select
  *
from
  unnest(
    $1::int[],    -- file_ids
    $2::varchar[] -- user_group_ids
  )

returning id, file_id, user_group_id, created_at;"
  |> pog.query
  |> pog.parameter(pog.array(fn(value) { pog.int(value) }, arg_1))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_2))
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

  "insert into
    products (
        name,
        description,
        status,
        price,
        created_at,
        updated_at
    )
values ($1, $2, $3, $4, now(), now()) returning *;"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(product_status_encoder(arg_3))
  |> pog.parameter(pog.float(arg_4))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `create_product_files` query
/// defined in `./src/auth_server/sql/create_product_files.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_product_files(
  db: pog.Connection,
  arg_1: Int,
  arg_2: List(Int),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "insert into product_file (product_id, file_id, display_order)
select $1, file_id, row_number() over () - 1
from unnest($2::int[]) as file_id;"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.array(fn(value) { pog.int(value) }, arg_2))
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

/// name: delete_file_by_id
/// Deletes a file only if it belongs to a product in user's groups
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_file_by_id(
  db: pog.Connection,
  arg_1: Int,
  arg_2: List(String),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- name: delete_file_by_id
-- Deletes a file only if it belongs to a product in user's groups
delete from files i
where
    i.id = $1
    and exists (
        select 1
        from
            product_file pf
            inner join product_user_group pug on pf.product_id = pug.product_id
        where
            pf.file_id = i.id
            and pug.user_group_id = any ($2)
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
where
    p.id = $1
    and exists (
        select 1
        from product_user_group pug
        where
            pug.product_id = p.id
            and pug.user_group_id = any ($2)
    );"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Runs the `delete_product_files` query
/// defined in `./src/auth_server/sql/delete_product_files.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_product_files(
  db: pog.Connection,
  arg_1: Int,
  arg_2: List(String),
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "delete from product_file
where product_id = $1
and exists (
    select 1 from product_user_group
    where product_user_group.product_id = product_file.product_id
    and product_user_group.user_group_id = any($2)
);"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `select_file_by_id` query
/// defined in `./src/auth_server/sql/select_file_by_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SelectFileByIdRow {
  SelectFileByIdRow(
    id: Int,
    filename: String,
    file_type: FileTypeEnum,
    context_type: ContextTypeEnum,
  )
}

/// name: select_file_by_id
/// Get file details by ID with user_group permission check
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_file_by_id(
  db: pog.Connection,
  arg_1: Int,
  arg_2: List(String),
) -> Result(pog.Returned(SelectFileByIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use filename <- decode.field(1, decode.string)
    use file_type <- decode.field(2, file_type_enum_decoder())
    use context_type <- decode.field(3, context_type_enum_decoder())
    decode.success(SelectFileByIdRow(id:, filename:, file_type:, context_type:))
  }

  "-- name: select_file_by_id
-- Get file details by ID with user_group permission check
select distinct
    files.id,
    files.filename,
    files.file_type,
    files.context_type
from files
    inner join file_user_group on files.id = file_user_group.file_id
where
    files.id = $1
    and file_user_group.user_group_id = any ($2)
    and files.deleted = false;"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `select_files` query
/// defined in `./src/auth_server/sql/select_files.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SelectFilesRow {
  SelectFilesRow(
    id: Int,
    filename: String,
    file_type: FileTypeEnum,
    context_type: ContextTypeEnum,
  )
}

/// Runs the `select_files` query
/// defined in `./src/auth_server/sql/select_files.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_files(
  db: pog.Connection,
  arg_1: List(String),
) -> Result(pog.Returned(SelectFilesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use filename <- decode.field(1, decode.string)
    use file_type <- decode.field(2, file_type_enum_decoder())
    use context_type <- decode.field(3, context_type_enum_decoder())
    decode.success(SelectFilesRow(id:, filename:, file_type:, context_type:))
  }

  "select files.id, files.filename, files.file_type, files.context_type
from files
    inner join file_user_group on files.id = file_user_group.file_id
where
    file_user_group.user_group_id = any ($1);"
  |> pog.query
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_1))
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
    images: String,
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
    use images <- decode.field(7, decode.string)
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
  COALESCE(json_agg(json_build_object('id', files.id, 'filename', files.filename, 'file_type', files.file_type, 'context_type', files.context_type)) filter (where files.id is not null), '[]'::json) as images
from products
inner join product_user_group on products.id = product_user_group.product_id
left join product_file on products.id = product_file.product_id
left join files on product_file.file_id = files.id
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
    images: String,
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
    use images <- decode.field(7, decode.string)
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
  COALESCE(
    json_agg(
      json_build_object(
        'id',
        files.id,
        'filename',
        files.filename,
        'file_type',
        files.file_type,
        'context_type',
        files.context_type
      )
    ) filter (
      where
        files.id is not null
    ),
    '[]' :: json
  ) as images
from
  products
  inner join product_user_group on products.id = product_user_group.product_id
  left join product_file on products.id = product_file.product_id
  left join files on product_file.file_id = files.id
where
  product_user_group.user_group_id = any($1)
group by
  products.id,
  products.name,
  products.description,
  products.status,
  products.price,
  products.created_at,
  products.updated_at
order by
  products.id;"
  |> pog.query
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_product` query
/// defined in `./src/auth_server/sql/update_product.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateProductRow {
  UpdateProductRow(
    id: Int,
    name: String,
    description: Option(String),
    status: ProductStatus,
    price: Float,
    created_at: Option(Timestamp),
    updated_at: Option(Timestamp),
  )
}

/// Runs the `update_product` query
/// defined in `./src/auth_server/sql/update_product.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_product(
  db: pog.Connection,
  arg_1: Int,
  arg_2: String,
  arg_3: String,
  arg_4: ProductStatus,
  arg_5: Float,
  arg_6: List(String),
) -> Result(pog.Returned(UpdateProductRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use description <- decode.field(2, decode.optional(decode.string))
    use status <- decode.field(3, product_status_decoder())
    use price <- decode.field(4, pog.numeric_decoder())
    use created_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    decode.success(UpdateProductRow(
      id:,
      name:,
      description:,
      status:,
      price:,
      created_at:,
      updated_at:,
    ))
  }

  "update products
set
    name = $2,
    description = $3,
    status = $4,
    price = $5,
    updated_at = now()
where id = $1
and exists (
    select 1 from product_user_group
    where product_user_group.product_id = products.id
    and product_user_group.user_group_id = any($6)
)
returning *;
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(product_status_encoder(arg_4))
  |> pog.parameter(pog.float(arg_5))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_6))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Enums -------------------------------------------------------------------

/// Corresponds to the Postgres `context_type_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ContextTypeEnum {
  Misc
  Product
  User
}

fn context_type_enum_decoder() -> decode.Decoder(ContextTypeEnum) {
  use context_type_enum <- decode.then(decode.string)
  case context_type_enum {
    "misc" -> decode.success(Misc)
    "product" -> decode.success(Product)
    "user" -> decode.success(User)
    _ -> decode.failure(Misc, "ContextTypeEnum")
  }
}

fn context_type_enum_encoder(context_type_enum) -> pog.Value {
  case context_type_enum {
    Misc -> "misc"
    Product -> "product"
    User -> "user"
  }
  |> pog.text
}/// Corresponds to the Postgres `file_type_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type FileTypeEnum {
  Unknown
  Video
  Image
}

fn file_type_enum_decoder() -> decode.Decoder(FileTypeEnum) {
  use file_type_enum <- decode.then(decode.string)
  case file_type_enum {
    "unknown" -> decode.success(Unknown)
    "video" -> decode.success(Video)
    "image" -> decode.success(Image)
    _ -> decode.failure(Unknown, "FileTypeEnum")
  }
}

fn file_type_enum_encoder(file_type_enum) -> pog.Value {
  case file_type_enum {
    Unknown -> "unknown"
    Video -> "video"
    Image -> "image"
  }
  |> pog.text
}/// Corresponds to the Postgres `product_status` enum.
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

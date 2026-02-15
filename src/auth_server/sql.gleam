//// This module contains the code to run the sql queries defined in
//// `./src/auth_server/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/json.{type Json}
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

/// A row you get from running the `create_or_update_platform_resources` query
/// defined in `./src/auth_server/sql/create_or_update_platform_resources.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateOrUpdatePlatformResourcesRow {
  CreateOrUpdatePlatformResourcesRow(
    id: Int,
    user_id: String,
    platform: IntegrationPlatform,
    resource_type: ResourceTypeEnum,
    external_id: String,
    resource_name: Option(String),
    resource_token: Option(String),
    metadata: Option(String),
    created_at: Option(Timestamp),
    updated_at: Option(Timestamp),
  )
}

/// Insert or update platform resources (like Facebook pages)
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_or_update_platform_resources(
  db: pog.Connection,
  arg_1: String,
  arg_2: IntegrationPlatform,
  arg_3: ResourceTypeEnum,
  arg_4: List(String),
  arg_5: List(String),
  arg_6: List(String),
) -> Result(pog.Returned(CreateOrUpdatePlatformResourcesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use user_id <- decode.field(1, decode.string)
    use platform <- decode.field(2, integration_platform_decoder())
    use resource_type <- decode.field(3, resource_type_enum_decoder())
    use external_id <- decode.field(4, decode.string)
    use resource_name <- decode.field(5, decode.optional(decode.string))
    use resource_token <- decode.field(6, decode.optional(decode.string))
    use metadata <- decode.field(7, decode.optional(decode.string))
    use created_at <- decode.field(8, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(9, decode.optional(pog.timestamp_decoder()))
    decode.success(CreateOrUpdatePlatformResourcesRow(
      id:,
      user_id:,
      platform:,
      resource_type:,
      external_id:,
      resource_name:,
      resource_token:,
      metadata:,
      created_at:,
      updated_at:,
    ))
  }

  "-- Insert or update platform resources (like Facebook pages)
INSERT INTO platform_resources (user_id, platform, resource_type, external_id, resource_name, resource_token)
SELECT 
  $1::VARCHAR,
  $2::integration_platform,
  $3::resource_type_enum,
  external_id,
  resource_name,
  resource_token
FROM unnest(
  $4::VARCHAR[],  -- external_ids
  $5::VARCHAR[],  -- resource_names
  $6::TEXT[]      -- resource_tokens
  -- able to include metadata if needed in future
) AS platform_resources(external_id, resource_name, resource_token)
ON CONFLICT (user_id, platform, resource_type, external_id) 
DO UPDATE SET 
  resource_name = EXCLUDED.resource_name,
  resource_token = EXCLUDED.resource_token,
  updated_at = CURRENT_TIMESTAMP
RETURNING id, user_id, platform, resource_type, external_id, resource_name, resource_token, metadata, created_at, updated_at;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(integration_platform_encoder(arg_2))
  |> pog.parameter(resource_type_enum_encoder(arg_3))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_4))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_5))
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_6))
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
    images: String,
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
    use images <- decode.field(7, decode.string)
    decode.success(CreateProductRow(
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

  "with inserted as (
  insert into
      products (
          name,
          description,
          status,
          price,
          created_at,
          updated_at
      )
  values ($1, $2, $3, $4, now(), now())
  returning *
)
select
  inserted.id,
  inserted.name,
  inserted.description,
  inserted.status,
  inserted.price,
  inserted.created_at,
  inserted.updated_at,
  COALESCE(
    json_agg(
      json_build_object(
        'id', files.id,
        'filename', files.filename,
        'file_type', files.file_type,
        'context_type', files.context_type
      )
    ) filter (where files.id is not null),
    '[]'::json
  ) as images
from inserted
left join product_file on inserted.id = product_file.product_id
left join files on product_file.file_id = files.id
group by inserted.id, inserted.name, inserted.description, inserted.status, inserted.price, inserted.created_at, inserted.updated_at;"
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

/// A row you get from running the `create_product_integrations` query
/// defined in `./src/auth_server/sql/create_product_integrations.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateProductIntegrationsRow {
  CreateProductIntegrationsRow(
    id: Int,
    product_id: Int,
    platform: IntegrationPlatform,
    resource_id: Option(String),
    resource_type: ResourceTypeEnum,
    sync_status: SyncStatus,
  )
}

/// name: create_product_integrations
/// Insert product integrations
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_product_integrations(
  db: pog.Connection,
  arg_1: Int,
  arg_2: List(IntegrationPlatform),
  arg_3: List(String),
  arg_4: List(ResourceTypeEnum),
) -> Result(pog.Returned(CreateProductIntegrationsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use product_id <- decode.field(1, decode.int)
    use platform <- decode.field(2, integration_platform_decoder())
    use resource_id <- decode.field(3, decode.optional(decode.string))
    use resource_type <- decode.field(4, resource_type_enum_decoder())
    use sync_status <- decode.field(5, sync_status_decoder())
    decode.success(CreateProductIntegrationsRow(
      id:,
      product_id:,
      platform:,
      resource_id:,
      resource_type:,
      sync_status:,
    ))
  }

  "-- name: create_product_integrations
-- Insert product integrations
insert into product_integrations (product_id, platform, resource_id, resource_type)
select $1, * from unnest(
  $2::integration_platform[],
  $3::varchar[],
  $4::resource_type_enum[]
)
returning id, product_id, platform, resource_id, resource_type, sync_status;"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(
    pog.array(fn(value) { integration_platform_encoder(value) }, arg_2),
  )
  |> pog.parameter(pog.array(fn(value) { pog.text(value) }, arg_3))
  |> pog.parameter(
    pog.array(fn(value) { resource_type_enum_encoder(value) }, arg_4),
  )
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

/// name: create_user_integration_token :exec
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_user_integration_token(
  db: pog.Connection,
  arg_1: String,
  arg_2: IntegrationPlatform,
  arg_3: String,
  arg_4: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- name: create_user_integration_token :exec
insert into
    user_integration_tokens (
        user_id,
        platform,
        access_token,
        token_type
    )
values ($1, $2, $3, $4) on conflict (user_id, platform) do
update
set
    access_token = excluded.access_token,
    token_type = excluded.token_type,
    updated_at = now();"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(integration_platform_encoder(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
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

/// A row you get from running the `select_platform_resource` query
/// defined in `./src/auth_server/sql/select_platform_resource.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SelectPlatformResourceRow {
  SelectPlatformResourceRow(
    id: Int,
    user_id: String,
    platform: IntegrationPlatform,
    resource_type: ResourceTypeEnum,
    external_id: String,
    resource_name: Option(String),
    resource_token: Option(String),
    metadata: Option(String),
    created_at: Option(Timestamp),
    updated_at: Option(Timestamp),
  )
}

/// Get a specific platform resource by user_id, platform, and external_id
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_platform_resource(
  db: pog.Connection,
  arg_1: String,
  arg_2: IntegrationPlatform,
  arg_3: String,
) -> Result(pog.Returned(SelectPlatformResourceRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use user_id <- decode.field(1, decode.string)
    use platform <- decode.field(2, integration_platform_decoder())
    use resource_type <- decode.field(3, resource_type_enum_decoder())
    use external_id <- decode.field(4, decode.string)
    use resource_name <- decode.field(5, decode.optional(decode.string))
    use resource_token <- decode.field(6, decode.optional(decode.string))
    use metadata <- decode.field(7, decode.optional(decode.string))
    use created_at <- decode.field(8, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(9, decode.optional(pog.timestamp_decoder()))
    decode.success(SelectPlatformResourceRow(
      id:,
      user_id:,
      platform:,
      resource_type:,
      external_id:,
      resource_name:,
      resource_token:,
      metadata:,
      created_at:,
      updated_at:,
    ))
  }

  "-- Get a specific platform resource by user_id, platform, and external_id
SELECT id, user_id, platform, resource_type, external_id, resource_name, resource_token, metadata, created_at, updated_at
FROM platform_resources
WHERE user_id = $1::VARCHAR 
  AND platform = $2::integration_platform 
  AND external_id = $3::VARCHAR;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(integration_platform_encoder(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `select_platform_resources_by_user` query
/// defined in `./src/auth_server/sql/select_platform_resources_by_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SelectPlatformResourcesByUserRow {
  SelectPlatformResourcesByUserRow(
    id: Int,
    user_id: String,
    platform: IntegrationPlatform,
    resource_type: ResourceTypeEnum,
    external_id: String,
    resource_name: Option(String),
    resource_token: Option(String),
    metadata: Option(String),
    created_at: Option(Timestamp),
    updated_at: Option(Timestamp),
  )
}

/// Get all platform resources for a user on a specific platform
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_platform_resources_by_user(
  db: pog.Connection,
  arg_1: String,
  arg_2: IntegrationPlatform,
) -> Result(pog.Returned(SelectPlatformResourcesByUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use user_id <- decode.field(1, decode.string)
    use platform <- decode.field(2, integration_platform_decoder())
    use resource_type <- decode.field(3, resource_type_enum_decoder())
    use external_id <- decode.field(4, decode.string)
    use resource_name <- decode.field(5, decode.optional(decode.string))
    use resource_token <- decode.field(6, decode.optional(decode.string))
    use metadata <- decode.field(7, decode.optional(decode.string))
    use created_at <- decode.field(8, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(9, decode.optional(pog.timestamp_decoder()))
    decode.success(SelectPlatformResourcesByUserRow(
      id:,
      user_id:,
      platform:,
      resource_type:,
      external_id:,
      resource_name:,
      resource_token:,
      metadata:,
      created_at:,
      updated_at:,
    ))
  }

  "-- Get all platform resources for a user on a specific platform
SELECT id, user_id, platform, resource_type, external_id, resource_name, resource_token, metadata, created_at, updated_at
FROM platform_resources
WHERE user_id = $1::VARCHAR 
  AND platform = $2::integration_platform
ORDER BY created_at DESC;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(integration_platform_encoder(arg_2))
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
    integrations: String,
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
    use integrations <- decode.field(8, decode.string)
    decode.success(SelectProductByIdRow(
      id:,
      name:,
      description:,
      status:,
      price:,
      created_at:,
      updated_at:,
      images:,
      integrations:,
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
  COALESCE(
    json_agg(
      json_build_object('id', files.id, 'filename', files.filename, 'file_type', files.file_type, 'context_type', files.context_type)
    ) filter (where files.id is not null), '[]'::json) as images,
  COALESCE(
    json_agg(
      json_build_object('platform', product_integrations.platform, 'resource_id', product_integrations.resource_id)
    ) filter (where product_integrations.id is not null and product_integrations.resource_id is not null), '[]'::json) as integrations
from products
inner join product_user_group on products.id = product_user_group.product_id
left join product_file on products.id = product_file.product_id
left join files on product_file.file_id = files.id
left join product_integrations on products.id = product_integrations.product_id
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

/// A row you get from running the `select_product_integrations` query
/// defined in `./src/auth_server/sql/select_product_integrations.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SelectProductIntegrationsRow {
  SelectProductIntegrationsRow(
    id: Int,
    product_id: Int,
    platform: IntegrationPlatform,
    resource_id: Option(String),
    resource_type: ResourceTypeEnum,
    sync_status: SyncStatus,
    external_id: Option(String),
    synced_at: Option(Timestamp),
  )
}

/// name: select_product_integrations
/// Get product integrations by product_id
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_product_integrations(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(SelectProductIntegrationsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use product_id <- decode.field(1, decode.int)
    use platform <- decode.field(2, integration_platform_decoder())
    use resource_id <- decode.field(3, decode.optional(decode.string))
    use resource_type <- decode.field(4, resource_type_enum_decoder())
    use sync_status <- decode.field(5, sync_status_decoder())
    use external_id <- decode.field(6, decode.optional(decode.string))
    use synced_at <- decode.field(7, decode.optional(pog.timestamp_decoder()))
    decode.success(SelectProductIntegrationsRow(
      id:,
      product_id:,
      platform:,
      resource_id:,
      resource_type:,
      sync_status:,
      external_id:,
      synced_at:,
    ))
  }

  "-- name: select_product_integrations
-- Get product integrations by product_id
select 
  id,
  product_id,
  platform,
  resource_id,
  resource_type,
  sync_status,
  external_id,
  synced_at
from product_integrations
where product_id = $1;"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `select_product_integrations_facebook_pages` query
/// defined in `./src/auth_server/sql/select_product_integrations_facebook_pages.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SelectProductIntegrationsFacebookPagesRow {
  SelectProductIntegrationsFacebookPagesRow(
    id: Int,
    product_id: Int,
    platform: IntegrationPlatform,
    resource_id: Option(String),
    resource_type: ResourceTypeEnum,
    sync_status: SyncStatus,
    external_id: Option(String),
    synced_at: Option(Timestamp),
  )
}

/// name: select_product_integrations_facebook_pages
/// Get product integrations by product_id and resource_type 'page' for Facebook platform
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_product_integrations_facebook_pages(
  db: pog.Connection,
  arg_1: Int,
) -> Result(
  pog.Returned(SelectProductIntegrationsFacebookPagesRow),
  pog.QueryError,
) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use product_id <- decode.field(1, decode.int)
    use platform <- decode.field(2, integration_platform_decoder())
    use resource_id <- decode.field(3, decode.optional(decode.string))
    use resource_type <- decode.field(4, resource_type_enum_decoder())
    use sync_status <- decode.field(5, sync_status_decoder())
    use external_id <- decode.field(6, decode.optional(decode.string))
    use synced_at <- decode.field(7, decode.optional(pog.timestamp_decoder()))
    decode.success(SelectProductIntegrationsFacebookPagesRow(
      id:,
      product_id:,
      platform:,
      resource_id:,
      resource_type:,
      sync_status:,
      external_id:,
      synced_at:,
    ))
  }

  "-- name: select_product_integrations_facebook_pages
-- Get product integrations by product_id and resource_type 'page' for Facebook platform
select
    id,
    product_id,
    platform,
    resource_id,
    resource_type,
    sync_status,
    external_id,
    synced_at
from product_integrations
where
    product_id = $1
    and platform = 'facebook'
    and resource_type = 'page';"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
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
    integrations: String,
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
    use integrations <- decode.field(8, decode.string)
    decode.success(SelectProductsRow(
      id:,
      name:,
      description:,
      status:,
      price:,
      created_at:,
      updated_at:,
      images:,
      integrations:,
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
  ) as images,
  COALESCE(
    json_agg(
      json_build_object(
        'platform',
        product_integrations.platform,
        'resource_id',
        product_integrations.resource_id
      )
    ) filter (
      where
        product_integrations.id is not null
        and product_integrations.resource_id is not null
    ),
    '[]' :: json
  ) as integrations
from
  products
  inner join product_user_group on products.id = product_user_group.product_id
  left join product_file on products.id = product_file.product_id
  left join files on product_file.file_id = files.id
  left join product_integrations on products.id = product_integrations.product_id
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

/// A row you get from running the `select_user_integration_token` query
/// defined in `./src/auth_server/sql/select_user_integration_token.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SelectUserIntegrationTokenRow {
  SelectUserIntegrationTokenRow(
    id: Int,
    user_id: String,
    platform: IntegrationPlatform,
    access_token: String,
    token_type: Option(String),
    updated_at: Option(Timestamp),
  )
}

/// name: select_user_integration_token
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn select_user_integration_token(
  db: pog.Connection,
  arg_1: String,
  arg_2: IntegrationPlatform,
) -> Result(pog.Returned(SelectUserIntegrationTokenRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use user_id <- decode.field(1, decode.string)
    use platform <- decode.field(2, integration_platform_decoder())
    use access_token <- decode.field(3, decode.string)
    use token_type <- decode.field(4, decode.optional(decode.string))
    use updated_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    decode.success(SelectUserIntegrationTokenRow(
      id:,
      user_id:,
      platform:,
      access_token:,
      token_type:,
      updated_at:,
    ))
  }

  "-- name: select_user_integration_token
select *
from user_integration_tokens
where
    user_id = $1
    and platform = $2
limit 1;"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(integration_platform_encoder(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_or_create_file_integration` query
/// defined in `./src/auth_server/sql/update_or_create_file_integration.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateOrCreateFileIntegrationRow {
  UpdateOrCreateFileIntegrationRow(
    id: Int,
    file_id: Int,
    platform: IntegrationPlatform,
    resource_id: Option(Int),
    external_id: String,
    synced_at: Option(Timestamp),
    created_at: Option(Timestamp),
  )
}

/// name: update_or_create_file_integration
/// update or create a file integration record
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_or_create_file_integration(
  db: pog.Connection,
  arg_1: Int,
  arg_2: IntegrationPlatform,
  arg_3: Int,
  arg_4: String,
  arg_5: Json,
) -> Result(pog.Returned(UpdateOrCreateFileIntegrationRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use file_id <- decode.field(1, decode.int)
    use platform <- decode.field(2, integration_platform_decoder())
    use resource_id <- decode.field(3, decode.optional(decode.int))
    use external_id <- decode.field(4, decode.string)
    use synced_at <- decode.field(5, decode.optional(pog.timestamp_decoder()))
    use created_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    decode.success(UpdateOrCreateFileIntegrationRow(
      id:,
      file_id:,
      platform:,
      resource_id:,
      external_id:,
      synced_at:,
      created_at:,
    ))
  }

  "-- name: update_or_create_file_integration
-- update or create a file integration record
insert into file_integration (file_id, platform, resource_id, external_id, metadata)
values ($1, $2, $3, $4, coalesce($5::jsonb, '{}'))
on conflict (file_id, platform, resource_id)
do update set
    external_id = EXCLUDED.external_id,
    metadata = EXCLUDED.metadata,
    synced_at = now(),
    updated_at = now()

returning id, file_id, platform, resource_id, external_id, synced_at, created_at;
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(integration_platform_encoder(arg_2))
  |> pog.parameter(pog.int(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(json.to_string(arg_5)))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_or_create_product_integration` query
/// defined in `./src/auth_server/sql/update_or_create_product_integration.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateOrCreateProductIntegrationRow {
  UpdateOrCreateProductIntegrationRow(
    id: Int,
    product_id: Int,
    platform: IntegrationPlatform,
    resource_id: Option(String),
    external_id: Option(String),
    sync_status: SyncStatus,
    synced_at: Option(Timestamp),
  )
}

/// name: update_or_create_product_integration_external_id
/// Create or update product integration with external_id and sync status after posting to platform
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_or_create_product_integration(
  db: pog.Connection,
  arg_1: Int,
  arg_2: IntegrationPlatform,
  arg_3: String,
  arg_4: SyncStatus,
  arg_5: String,
) -> Result(pog.Returned(UpdateOrCreateProductIntegrationRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use product_id <- decode.field(1, decode.int)
    use platform <- decode.field(2, integration_platform_decoder())
    use resource_id <- decode.field(3, decode.optional(decode.string))
    use external_id <- decode.field(4, decode.optional(decode.string))
    use sync_status <- decode.field(5, sync_status_decoder())
    use synced_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    decode.success(UpdateOrCreateProductIntegrationRow(
      id:,
      product_id:,
      platform:,
      resource_id:,
      external_id:,
      sync_status:,
      synced_at:,
    ))
  }

  "-- name: update_or_create_product_integration_external_id
-- Create or update product integration with external_id and sync status after posting to platform
insert into product_integrations (product_id, platform, external_id, sync_status, synced_at, resource_id)
values ($1, $2, $3, $4, now(), $5)
on conflict (product_id, platform)
do update set
  external_id = EXCLUDED.external_id,
  sync_status = EXCLUDED.sync_status,
  synced_at = now()
returning id, product_id, platform, resource_id, external_id, sync_status, synced_at;
"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(integration_platform_encoder(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(sync_status_encoder(arg_4))
  |> pog.parameter(pog.text(arg_5))
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
    images: String,
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
    use images <- decode.field(7, decode.string)
    decode.success(UpdateProductRow(
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

  "with updated as (
  update products
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
  returning *
)
select
  updated.id,
  updated.name,
  updated.description,
  updated.status,
  updated.price,
  updated.created_at,
  updated.updated_at,
  COALESCE(
    json_agg(
      json_build_object(
        'id', files.id,
        'filename', files.filename,
        'file_type', files.file_type,
        'context_type', files.context_type
      )
    ) filter (where files.id is not null),
    '[]'::json
  ) as images
from updated
left join product_file on updated.id = product_file.product_id
left join files on product_file.file_id = files.id
group by updated.id, updated.name, updated.description, updated.status, updated.price, updated.created_at, updated.updated_at;
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

/// A row you get from running the `update_product_integration_external_id` query
/// defined in `./src/auth_server/sql/update_product_integration_external_id.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateProductIntegrationExternalIdRow {
  UpdateProductIntegrationExternalIdRow(
    id: Int,
    product_id: Int,
    platform: IntegrationPlatform,
    resource_id: Option(String),
    external_id: Option(String),
    sync_status: SyncStatus,
    synced_at: Option(Timestamp),
  )
}

/// name: update_product_integration_external_id
/// Update external_id for a product integration
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_product_integration_external_id(
  db: pog.Connection,
  arg_1: String,
  arg_2: Int,
  arg_3: String,
) -> Result(pog.Returned(UpdateProductIntegrationExternalIdRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use product_id <- decode.field(1, decode.int)
    use platform <- decode.field(2, integration_platform_decoder())
    use resource_id <- decode.field(3, decode.optional(decode.string))
    use external_id <- decode.field(4, decode.optional(decode.string))
    use sync_status <- decode.field(5, sync_status_decoder())
    use synced_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    decode.success(UpdateProductIntegrationExternalIdRow(
      id:,
      product_id:,
      platform:,
      resource_id:,
      external_id:,
      sync_status:,
      synced_at:,
    ))
  }

  "-- name: update_product_integration_external_id
-- Update external_id for a product integration
update product_integrations
set 
  external_id = $1,
  sync_status = 'synced',
  synced_at = now(),
  updated_at = now()
where product_id = $2 and resource_id = $3
returning id, product_id, platform, resource_id, external_id, sync_status, synced_at;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.parameter(pog.text(arg_3))
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
}/// Corresponds to the Postgres `integration_platform` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type IntegrationPlatform {
  Facebook
  Instagram
}

fn integration_platform_decoder() -> decode.Decoder(IntegrationPlatform) {
  use integration_platform <- decode.then(decode.string)
  case integration_platform {
    "facebook" -> decode.success(Facebook)
    "instagram" -> decode.success(Instagram)
    _ -> decode.failure(Facebook, "IntegrationPlatform")
  }
}

fn integration_platform_encoder(integration_platform) -> pog.Value {
  case integration_platform {
    Facebook -> "facebook"
    Instagram -> "instagram"
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
}/// Corresponds to the Postgres `resource_type_enum` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ResourceTypeEnum {
  Page
}

fn resource_type_enum_decoder() -> decode.Decoder(ResourceTypeEnum) {
  use resource_type_enum <- decode.then(decode.string)
  case resource_type_enum {
    "page" -> decode.success(Page)
    _ -> decode.failure(Page, "ResourceTypeEnum")
  }
}

fn resource_type_enum_encoder(resource_type_enum) -> pog.Value {
  case resource_type_enum {
    Page -> "page"
  }
  |> pog.text
}/// Corresponds to the Postgres `sync_status` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type SyncStatus {
  Failed
  Synced
  Pending
}

fn sync_status_decoder() -> decode.Decoder(SyncStatus) {
  use sync_status <- decode.then(decode.string)
  case sync_status {
    "failed" -> decode.success(Failed)
    "synced" -> decode.success(Synced)
    "pending" -> decode.success(Pending)
    _ -> decode.failure(Failed, "SyncStatus")
  }
}

fn sync_status_encoder(sync_status) -> pog.Value {
  case sync_status {
    Failed -> "failed"
    Synced -> "synced"
    Pending -> "pending"
  }
  |> pog.text
}

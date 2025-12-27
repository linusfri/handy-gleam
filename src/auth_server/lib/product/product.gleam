import auth_server/lib/file/types as file_types
import auth_server/lib/file_handlers/file_handler
import auth_server/lib/product/transform
import auth_server/lib/user/types.{type User}
import auth_server/sql.{type SelectProductsRow, SelectProductsRow}
import auth_server/web
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option
import gleam/result
import gleam/string

pub fn create_product(
  data data: Dynamic,
  user user: User,
  context ctx: web.Context,
) -> Result(Nil, String) {
  use product_request <- result.try(
    transform.create_product_request_decoder(data)
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

fn create_product_images_files(
  product_name: String,
  images: List(transform.CreateProductImageRequest),
) -> Result(List(file_types.CreatedFile), String) {
  let valid_images =
    list.filter_map(images, fn(img) {
      let filename = option.unwrap(img.filename, "no_filename")
      let filetype = option.unwrap(img.mimetype, "application/octet-stream")
      case img.filename {
        option.Some(name) if name != "" ->
          Ok(file_types.File(
            id: option.None,
            data: img.data,
            filename: product_name <> filename,
            file_type: filetype,
            context_type: sql.Product,
          ))
        _ -> Error(Nil)
      }
    })

  case valid_images {
    [] -> Ok([])
    _ -> {
      list.map(valid_images, fn(image) {
        use created_filename <- result.try(file_handler.create_file(image))

        Ok(file_types.CreatedFile(
          filename: created_filename,
          file_type: image.file_type,
          context_type: image.context_type,
        ))
      })
      |> result.all()
    }
  }
}

fn create_product_images_in_db(
  ctx: web.Context,
  product_id: Int,
  created_files: List(file_types.CreatedFile),
) -> Result(List(file_types.CreatedFile), String) {
  case created_files {
    [] -> Ok([])
    _ -> {
      let file_names = list.map(created_files, fn(file) { file.filename })
      let file_types = list.map(created_files, fn(file) { file.file_type })
      let file_contexts =
        list.map(created_files, fn(file) { file.context_type })

      // Create all file records in database
      use created_images <- result.try(
        sql.create_files(ctx.db, file_names, file_types, file_contexts)
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

      Ok(created_files)
    }
  }
}

/// Creates images if base64 string is provided
pub fn create_product_images(
  ctx ctx: web.Context,
  product_name product_name: String,
  images images: List(transform.CreateProductImageRequest),
  product_id product_id: Int,
) -> Result(List(file_types.CreatedFile), String) {
  use created_files <- result.try(create_product_images_files(
    product_name,
    images,
  ))

  create_product_images_in_db(ctx, product_id, created_files)
}

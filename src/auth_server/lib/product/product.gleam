import auth_server/lib/file/types as file_types
import auth_server/lib/file_handlers/file_handler
import auth_server/lib/product/transform
import auth_server/lib/user/types.{type User}
import auth_server/lib/utils/logger
import auth_server/sql.{type SelectProductsRow, SelectProductsRow}
import auth_server/web
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import pog

pub fn create_product(
  data data: Dynamic,
  user user: User,
  context ctx: web.Context,
) -> Result(Nil, String) {
  use product_request <- result.try(
    transform.create_product_request_decoder(data)
    |> result.map_error(fn(errors) {
      logger.log_error_with_context("create_product:decode_request", errors)
      string.inspect(errors)
    }),
  )

  pog.transaction(ctx.db, fn(tx) {
    use create_product_response <- result.try(
      sql.create_product(
        tx,
        product_request.name,
        option.unwrap(product_request.description, ""),
        product_request.status,
        product_request.price,
      )
      |> result.map_error(fn(err) {
        logger.log_error_with_context("create_product:sql.create_product", err)
        "Could not create product"
      }),
    )

    use first_product <- result.try(case create_product_response.rows {
      [first, ..] -> Ok(first)
      [] -> Error("No product ID returned from db query")
    })

    use _ <- result.try(create_product_images_tx(
      tx,
      first_product.name,
      product_request.images,
      first_product.id,
    ))

    use _ <- result.try(
      sql.create_products_user_groups(tx, [first_product.id], user.groups)
      |> result.map_error(fn(err) {
        logger.log_error_with_context("create_product:link_user_groups", err)
        string.inspect(err)
      }),
    )

    Ok(Nil)
  })
  |> result.map_error(fn(err) {
    logger.log_error_with_context("create_product:transaction", err)
    "Transaction failed: " <> string.inspect(err)
  })
}

pub fn delete_product(
  product_id product_id: Int,
  context ctx: web.Context,
  user user: User,
) -> Result(Nil, String) {
  use _ <- result.try(
    sql.delete_product(ctx.db, product_id, user.groups)
    |> result.map_error(fn(err) {
      logger.log_error_with_context("delete_product:sql.delete_product", err)
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
      logger.log_error_with_context(
        "get_product_by_id:sql.select_product_by_id",
        err,
      )
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

fn create_product_images_tx(
  tx: pog.Connection,
  product_name: String,
  images: List(transform.CreateProductImageRequest),
  product_id: Int,
) -> Result(List(file_types.CreatedFile), String) {
  let #(existing_images, new_images) =
    list.partition(images, fn(img) {
      case img.kind {
        transform.Existing -> True
        transform.New -> False
      }
    })

  use _ <- result.try(link_existing_images_tx(tx, product_id, existing_images))

  create_new_images_tx(tx, product_name, product_id, new_images)
}

fn create_product_images_files(
  product_name: String,
  images: List(transform.CreateProductImageRequest),
) -> Result(List(file_types.CreatedFile), String) {
  let valid_images =
    list.filter_map(images, fn(image) {
      let filename = option.unwrap(image.filename, "no_filename")
      let filetype = option.unwrap(image.mimetype, "application/octet-stream")
      case image.filename {
        option.Some(name) if name != "" ->
          Ok(file_types.File(
            id: option.None,
            data: image.data,
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

fn link_existing_images_tx(
  tx: pog.Connection,
  product_id: Int,
  images: List(transform.CreateProductImageRequest),
) -> Result(Nil, String) {
  let ids =
    list.filter_map(images, fn(img) {
      case img.id {
        option.Some(id) -> Ok(id)
        option.None -> Error(Nil)
      }
    })

  case ids {
    [] -> Ok(Nil)
    _ ->
      sql.create_product_images(tx, product_id, ids)
      |> result.map(fn(_) { Nil })
      |> result.map_error(fn(err) {
        "Failed to link existing images: " <> string.inspect(err)
      })
  }
}

fn create_new_images_tx(
  tx: pog.Connection,
  product_name: String,
  product_id: Int,
  images: List(transform.CreateProductImageRequest),
) -> Result(List(file_types.CreatedFile), String) {
  use created_files <- result.try(create_product_images_files(
    product_name,
    images,
  ))

  case created_files {
    [] -> Ok([])
    _ -> {
      let file_names = list.map(created_files, fn(file) { file.filename })
      let file_types = list.map(created_files, fn(file) { file.file_type })
      let file_contexts =
        list.map(created_files, fn(file) { file.context_type })

      // Create all file records in database
      use created_images <- result.try(
        sql.create_files(tx, file_names, file_types, file_contexts)
        |> result.map_error(fn(err) {
          "Failed to create images: " <> string.inspect(err)
        }),
      )

      // Link all images to the product
      let image_ids = list.map(created_images.rows, fn(row) { row.id })
      use _ <- result.try(
        sql.create_product_images(tx, product_id, image_ids)
        |> result.map_error(fn(err) {
          "Failed to link product images: " <> string.inspect(err)
        }),
      )

      Ok(created_files)
    }
  }
}

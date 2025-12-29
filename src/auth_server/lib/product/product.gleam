import auth_server/lib/product/transform
import auth_server/lib/user/types.{type User}
import auth_server/lib/utils/logger
import auth_server/sql.{type SelectProductsRow, SelectProductsRow}
import auth_server/web
import gleam/dynamic.{type Dynamic}
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

    use _ <- result.try(link_images_tx(
      tx,
      first_product.id,
      product_request.image_ids,
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
      "delete_product:sql.delete_product | " <> string.inspect(err)
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
      "product:get_product_by_id:sql.select_product_by_id | "
      <> string.inspect(err)
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
    [] ->
      Error("product:get_product_by_id | Product not found or access denied")
  }
}

pub fn get_products(
  ctx: web.Context,
  user: User,
) -> Result(List(SelectProductsRow), String) {
  case sql.select_products(ctx.db, user.groups) {
    Ok(products) -> {
      Ok(products.rows)
    }
    Error(error) -> Error("product:get_products | " <> string.inspect(error))
  }
}

fn link_images_tx(
  tx: pog.Connection,
  product_id: Int,
  images: List(Int),
) -> Result(Nil, String) {
  sql.create_product_files(tx, product_id, images)
  |> result.map(fn(_) { Nil })
  |> result.map_error(fn(err) {
    "product:link_existing_images:sql.create_product_images | "
    <> string.inspect(err)
  })
}

import auth_server/lib/product/transform
import auth_server/lib/user/types.{type User}
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
    transform.product_mutation_request_decoder(data)
    |> result.map_error(fn(errors) { string.inspect(errors) }),
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
        "Could not create product | " <> string.inspect(err)
      }),
    )

    use first_product <- result.try(case create_product_response.rows {
      [first, ..] -> Ok(first)
      [] -> Error("No product ID returned from db query")
    })

    use _ <- result.try(link_files_tx(
      tx,
      first_product.id,
      product_request.image_ids,
    ))

    use _ <- result.try(
      sql.create_products_user_groups(tx, [first_product.id], user.groups)
      |> result.map_error(fn(err) { string.inspect(err) }),
    )

    Ok(Nil)
  })
  |> result.map_error(fn(err) { "Transaction failed: " <> string.inspect(err) })
}

pub fn update_product(
  product_id product_id: Int,
  product_data product_data: Dynamic,
  context ctx: web.Context,
  user user: User,
) {
  use product_edit_request <- result.try(
    transform.product_mutation_request_decoder(product_data)
    |> result.map_error(fn(err) { string.inspect(err) }),
  )

  pog.transaction(ctx.db, fn(tx) {
    use update_product_response <- result.try(
      sql.update_product(
        tx,
        product_id,
        product_edit_request.name,
        option.unwrap(product_edit_request.description, ""),
        product_edit_request.status,
        product_edit_request.price,
        user.groups,
      )
      |> result.map_error(fn(err) {
        "Could not update product | " <> string.inspect(err)
      }),
    )

    use _ <- result.try(
      sql.delete_product_files(tx, product_id, user.groups)
      |> result.map_error(fn(err) {
        "Could not delete existing product files | " <> string.inspect(err)
      }),
    )

    use first_product <- result.try(case update_product_response.rows {
      [first, ..] -> Ok(first)
      [] -> Error("No product ID returned from db query")
    })

    use _ <- result.try(link_files_tx(
      tx,
      first_product.id,
      product_edit_request.image_ids,
    ))

    Ok(Nil)
  })
  |> result.map_error(fn(err) { "Transaction failed: " <> string.inspect(err) })
}

pub fn delete_product(
  product_id product_id: Int,
  context ctx: web.Context,
  user user: User,
) -> Result(Nil, String) {
  pog.transaction(ctx.db, fn(tx) {
    use _ <- result.try(
      sql.delete_product(tx, product_id, user.groups)
      |> result.map_error(fn(err) {
        "delete_product:sql.delete_product | " <> string.inspect(err)
      }),
    )

    Ok(Nil)
  })
  |> result.map_error(fn(err) { "Transaction failed: " <> string.inspect(err) })
}

pub fn get_product_by_id(
  product_id product_id: Int,
  context ctx: web.Context,
  user user: User,
) -> Result(SelectProductsRow, String) {
  pog.transaction(ctx.db, fn(tx) {
    use product_result <- result.try(
      sql.select_product_by_id(tx, product_id, user.groups)
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
  })
  |> result.map_error(fn(err) { "Transaction failed: " <> string.inspect(err) })
}

pub fn get_products(
  ctx: web.Context,
  user: User,
) -> Result(List(SelectProductsRow), String) {
  pog.transaction(ctx.db, fn(tx) {
    case sql.select_products(tx, user.groups) {
      Ok(products) -> {
        Ok(products.rows)
      }
      Error(error) -> Error("product:get_products | " <> string.inspect(error))
    }
  })
  |> result.map_error(fn(err) { "Transaction failed: " <> string.inspect(err) })
}

fn link_files_tx(
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

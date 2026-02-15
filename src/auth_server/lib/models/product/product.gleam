import auth_server/global_types
import auth_server/lib/models/product/product_transform
import auth_server/lib/models/user/user_types.{type User}
import auth_server/sql.{type SelectProductsRow, SelectProductsRow}
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import pog

pub fn create_product(
  data data: Dynamic,
  user user: User,
  context ctx: global_types.Context,
) -> Result(sql.CreateProductRow, String) {
  use create_product_request <- result.try(
    product_transform.product_mutation_request_decoder(data)
    |> result.map_error(fn(errors) { string.inspect(errors) }),
  )

  pog.transaction(ctx.db, fn(tx) {
    use create_product_db_result <- result.try(
      sql.create_product(
        tx,
        create_product_request.name,
        option.unwrap(create_product_request.description, ""),
        create_product_request.status,
        create_product_request.price,
      )
      |> result.map_error(fn(err) {
        "Could not create product | " <> string.inspect(err)
      }),
    )

    use created_product_row <- result.try(case create_product_db_result.rows {
      [first, ..] -> Ok(first)
      [] -> Error("No product ID returned from db query")
    })

    use _ <- result.try(link_files_tx(
      tx,
      created_product_row.id,
      create_product_request.image_ids,
    ))

    use _ <- result.try(
      sql.create_products_user_groups(tx, [created_product_row.id], user.groups)
      |> result.map_error(fn(err) { string.inspect(err) }),
    )

    use _ <- result.try(create_product_integrations_tx(
      tx,
      created_product_row.id,
      create_product_request.integrations,
    ))

    Ok(created_product_row)
  })
  |> result.map_error(fn(err) { "Transaction failed: " <> string.inspect(err) })
}

fn create_product_integrations_tx(
  tx: pog.Connection,
  product_id: Int,
  product_integrations: List(product_transform.ProductIntegration),
) {
  case product_integrations {
    [] -> Ok(pog.Returned(count: 0, rows: []))
    integrations -> {
      let platforms =
        integrations
        |> list.map(fn(integration) { integration.platform })
      let resource_ids =
        integrations
        |> list.map(fn(integration) { integration.resource_id })
      let resource_types =
        integrations
        |> list.map(fn(integration) { integration.resource_type })

      sql.create_product_integrations(
        tx,
        product_id,
        platforms,
        resource_ids,
        resource_types,
      )
      |> result.map_error(fn(err) { string.inspect(err) })
    }
  }
}

pub fn update_product(
  product_id product_id: Int,
  product_data product_data: Dynamic,
  context ctx: global_types.Context,
  user user: User,
) {
  use product_edit_request <- result.try(
    product_transform.product_mutation_request_decoder(product_data)
    |> result.map_error(fn(err) { string.inspect(err) }),
  )

  pog.transaction(ctx.db, fn(tx) {
    use update_product_db_result <- result.try(
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

    use updated_product_row <- result.try(case update_product_db_result.rows {
      [first_product, ..] -> Ok(first_product)
      [] -> Error("No product row returned from db query")
    })

    use _ <- result.try(link_files_tx(
      tx,
      updated_product_row.id,
      product_edit_request.image_ids,
    ))

    Ok(updated_product_row)
  })
  |> result.map_error(fn(err) { "Transaction failed: " <> string.inspect(err) })
}

pub fn delete_product(
  product_id product_id: Int,
  context ctx: global_types.Context,
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
  context ctx: global_types.Context,
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
          integrations: product.integrations,
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
  ctx: global_types.Context,
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

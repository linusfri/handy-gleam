import auth_server/lib/product/product.{
  create_product_image, select_products_row_to_json,
}
import auth_server/lib/user/types.{type User}
import auth_server/sql
import auth_server/web
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import wisp

pub fn get_products(ctx: web.Context, user: User) {
  case sql.select_products(ctx.db, user.groups) {
    Ok(products) -> {
      let products_json =
        products.rows
        |> list.map(select_products_row_to_json)
        |> json.array(of: fn(x) { x })

      wisp.json_response(json.to_string(products_json), 200)
    }
    Error(error) -> wisp.json_response(string.inspect(error), 500)
  }
}

pub fn create_product(
  req: request.Request(wisp.Connection),
  ctx: web.Context,
  user: User,
) {
  use <- wisp.require_method(req, http.Post)
  use json_body <- wisp.require_json(req)

  // First creates the product
  let created_product_id_rows = {
    use product <- result.try(
      product.create_product_row_decoder(json_body)
      |> result.map_error(fn(errors) {
        wisp.json_response(string.inspect(errors), 400)
      }),
    )

    use create_product_response <- result.try(
      sql.create_product(
        ctx.db,
        product.name,
        option.unwrap(product.description, ""),
        product.status,
        product.price,
      )
      |> result.map_error(fn(_) {
        wisp.json_response("Could not create product", 500)
      }),
    )

    use _path <- result.try(
      create_product_image(product)
      |> result.map_error(fn(err) {
        wisp.json_response("Image upload failed: " <> err, 500)
      }),
    )

    Ok(create_product_response.rows)
  }

  // Then connects the created product to the groups the user is part of
  let products_users_join_creation_result = {
    use rows <- result.try(created_product_id_rows)
    let product_ids = list.map(rows, fn(row) { row.id })
    use _pog_response <- result.try(
      sql.create_products_user_groups(ctx.db, product_ids, user.groups)
      |> result.map_error(fn(err) {
        wisp.json_response(string.inspect(err), 500)
      }),
    )

    Ok(wisp.json_response("Product created", 201))
  }

  case products_users_join_creation_result {
    Ok(response) -> response
    Error(error_response) -> error_response
  }
}

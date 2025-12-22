import auth_server/lib/product/product.{select_products_row_to_json}
import auth_server/lib/user/types.{type User}
import auth_server/sql
import auth_server/web
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import wisp

pub fn get_products(ctx: web.Context, user: User) {
  case sql.select_products(ctx.db, user.groups) {
    Ok(products) -> {
      let products_json =
        products.rows
        |> list.map(select_products_row_to_json)
        |> json.array(of: fn(x) { x })

      Ok(json.to_string(products_json))
    }
    Error(_) -> {
      Error("{\"error\": \"Could not get products\"}")
    }
  }
}

pub fn create_product(
  req: request.Request(wisp.Connection),
  ctx: web.Context,
  user: User,
) {
  use <- wisp.require_method(req, http.Post)
  use json_body <- wisp.require_json(req)

  let created_product_id_rows = case
    product.create_product_row_decoder(json_body)
  {
    Ok(product) ->
      case
        sql.create_product(
          ctx.db,
          product.name,
          option.unwrap(product.description, ""),
          product.status,
          product.price,
        )
      {
        Ok(create_product_response) -> Ok(create_product_response.rows)
        Error(_) -> Error(wisp.json_response("Could not create product", 500))
      }
    Error(_) -> Error(wisp.json_response("Could not decode product", 400))
  }

  case created_product_id_rows {
    Ok(id_rows) -> {
      let product_ids = list.map(id_rows, fn(row) { row.id })
      case sql.create_products_user_groups(ctx.db, product_ids, user.groups) {
        Ok(_) -> wisp.json_response("Product created", 201)
        Error(err) -> {
          wisp.json_response(string.inspect(err), 500)
        }
      }
    }
    Error(wisp_error) -> wisp_error
  }
}

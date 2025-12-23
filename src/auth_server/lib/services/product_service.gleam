import auth_server/lib/file_handlers/image_handler
import auth_server/lib/product/product.{select_products_row_to_json}
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
import simplifile
import wisp
import youid/uuid

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

/// Creates an image if base64 string is provided
fn create_product_image(product: product.CreateProductRow) {
  case product.image {
    option.Some(base64_image) if base64_image != "" -> {
      {
        // Ensure directory exists
        let _ = simplifile.create_directory_all("uploads/products")

        let filename =
          "product_" <> product.name <> "_" <> uuid.v4_string() <> ".png"
        let upload_path = "uploads/products/" <> filename

        image_handler.save_base64_image(base64_image, upload_path)
        |> result.replace(upload_path)
      }
    }
    _ -> Ok("")
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
        Ok(create_product_response) -> {
          let image_result = create_product_image(product)

          case image_result {
            Ok(_path) -> Ok(create_product_response.rows)
            Error(err) ->
              Error(wisp.json_response("Image upload failed: " <> err, 500))
          }
        }
        Error(_) -> Error(wisp.json_response("Could not create product", 500))
      }
    Error(errors) -> {
      Error(wisp.json_response(string.inspect(errors), 400))
    }
  }

  case created_product_id_rows {
    Ok(rows) -> {
      let product_ids = list.map(rows, fn(row) { row.id })
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

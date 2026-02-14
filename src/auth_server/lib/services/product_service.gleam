import auth_server/global_types
import auth_server/lib/models/integration/facebook_instagram
import auth_server/lib/models/product/product
import auth_server/lib/models/product/product_transform
import auth_server/lib/models/product/product_types.{FacebookProduct}
import auth_server/lib/models/user/user_types.{type User}
import auth_server/lib/utils/logger
import auth_server/sql
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import wisp

pub fn get_products(ctx: global_types.Context, user: User) {
  case product.get_products(ctx, user) {
    Ok(products) -> {
      products
      |> list.map(product_transform.product_to_json)
      |> json.array(of: fn(json_product) { json_product })
      |> json.to_string
      |> wisp.json_response(200)
    }
    Error(err) -> {
      logger.log_error(err)
      wisp.json_response(string.inspect(err), 500)
    }
  }
}

pub fn create_product(
  req: request.Request(wisp.Connection),
  ctx: global_types.Context,
  user: User,
) {
  use <- wisp.require_method(req, http.Post)
  use json_body <- wisp.require_json(req)

  case product.create_product(data: json_body, context: ctx, user: user) {
    Ok(created_product) -> {
      let facebook_post_created =
        facebook_instagram.update_or_create_post_on_page(
          ctx,
          user,
          sql.Facebook,
          FacebookProduct(
            id: created_product.id,
            name: created_product.name,
            status: created_product.status,
            price: created_product.price,
            images: [],
            description: created_product.description,
          ),
        )

      case result.is_error(facebook_post_created) {
        False -> wisp.json_response("Product created", 201)
        True ->
          wisp.json_response(
            "Product created, but facebook post could not be created",
            201,
          )
      }
    }
    Error(err) -> {
      logger.log_error(err)
      wisp.json_response(err, 500)
    }
  }
}

pub fn delete_product(
  req: request.Request(wisp.Connection),
  ctx: global_types.Context,
  user: User,
  product_id_str: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)

  let delete_product_result = {
    use product_id <- result.try(
      int.parse(product_id_str)
      |> result.replace_error("Invalid product id"),
    )

    product.delete_product(product_id: product_id, context: ctx, user: user)
  }

  case delete_product_result {
    Ok(_) -> wisp.json_response("Product deleted successfully", 200)
    Error("Invalid product id") -> wisp.json_response("Invalid product id", 400)
    Error(err) -> {
      logger.log_error(err)
      wisp.json_response(err, 500)
    }
  }
}

pub fn get_product(
  req: request.Request(wisp.Connection),
  ctx: global_types.Context,
  user: User,
  product_id_str: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let get_product_result = {
    use product_id <- result.try(
      int.parse(product_id_str)
      |> result.replace_error("Invalid product id"),
    )

    product.get_product_by_id(product_id: product_id, context: ctx, user: user)
  }

  case get_product_result {
    Ok(product) -> {
      wisp.json_response(
        json.to_string(product_transform.product_to_json(product)),
        200,
      )
    }
    Error("Invalid product id" as err) -> {
      logger.log_error(err)
      wisp.json_response(err, 400)
    }
    Error("Product not found or access denied" as err) -> {
      logger.log_error(err)
      wisp.json_response("Product not found or access denied", 404)
    }
    Error(err) -> {
      logger.log_error(err)
      wisp.json_response(err, 500)
    }
  }
}

pub fn update_product(
  req req: request.Request(wisp.Connection),
  ctx ctx: global_types.Context,
  user user: User,
  product_id product_id_str: String,
) {
  use json_body <- wisp.require_json(req)

  let update_product_result = {
    use product_id <- result.try(
      int.parse(product_id_str)
      |> result.replace_error("Invalid product id"),
    )

    product.update_product(
      product_data: json_body,
      product_id: product_id,
      context: ctx,
      user: user,
    )
  }

  case update_product_result {
    Ok(updated_product) -> {
      let facebook_post_created =
        facebook_instagram.update_or_create_post_on_page(
          ctx,
          user,
          sql.Facebook,
          FacebookProduct(
            id: updated_product.id,
            name: updated_product.name,
            status: updated_product.status,
            price: updated_product.price,
            images: [],
            description: updated_product.description,
          ),
        )

      case result.is_error(facebook_post_created) {
        False -> wisp.json_response("Product updated", 201)
        True ->
          wisp.json_response(
            "Product updated, but facebook post could not be created",
            201,
          )
      }
    }
    Error(err) -> {
      wisp.json_response(err, 500)
    }
  }
}

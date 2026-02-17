import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import handygleam/global_types
import handygleam/lib/models/error/app_error.{
  AppError, InvalidPayload, to_http_response,
}
import handygleam/lib/models/product/product
import handygleam/lib/models/product/product_transform
import handygleam/lib/models/user/user_types.{type User}
import handygleam/lib/services/integration_service
import handygleam/lib/utils/logger
import wisp

pub fn get_products(
  ctx: global_types.Context,
  user: User,
) -> response.Response(wisp.Body) {
  case product.get_products(ctx, user) {
    Ok(products) -> {
      products
      |> list.map(product_transform.product_to_json)
      |> json.array(of: fn(json_product) { json_product })
      |> json.to_string
      |> wisp.json_response(200)
    }
    Error(error) -> {
      logger.log_error(error)
      to_http_response(error)
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
    Ok(created_product_row) -> {
      let facebook_product =
        product_transform.create_product_row_to_facebook_product(
          created_product_row,
        )

      case
        integration_service.sync_product_to_facebook(
          ctx,
          user,
          facebook_product,
        )
      {
        False -> wisp.json_response("Product created", 201)
        True ->
          wisp.json_response(
            "Product created, but facebook post could not be created",
            201,
          )
      }
    }
    Error(error) -> {
      logger.log_error(error)
      to_http_response(error)
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
      |> result.replace_error(AppError(
        error: InvalidPayload,
        message: "Invalid product id",
      )),
    )

    product.delete_product(product_id: product_id, context: ctx, user: user)
  }

  case delete_product_result {
    Ok(_) -> wisp.json_response("Product deleted successfully", 200)
    Error(err) -> {
      logger.log_error(err)
      to_http_response(err)
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
      |> result.replace_error(AppError(
        error: InvalidPayload,
        message: "Invalid product id",
      )),
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
    Error(error) -> {
      logger.log_error(error)
      to_http_response(error)
    }
  }
}

pub fn update_product(
  req req: request.Request(wisp.Connection),
  ctx ctx: global_types.Context,
  user user: User,
  product_id product_id_str: String,
) {
  use update_product_data <- wisp.require_json(req)

  let update_product_result = {
    use product_id <- result.try(
      int.parse(product_id_str)
      |> result.replace_error(AppError(
        error: InvalidPayload,
        message: "Invalid product id",
      )),
    )

    product.update_product(
      product_data: update_product_data,
      product_id: product_id,
      context: ctx,
      user: user,
    )
  }

  case update_product_result {
    Ok(updated_product_row) -> {
      let facebook_product =
        product_transform.update_product_row_to_facebook_product(
          updated_product_row,
        )

      case
        integration_service.sync_product_to_facebook(
          ctx,
          user,
          facebook_product,
        )
      {
        False -> wisp.json_response("Product updated", 201)
        True ->
          wisp.json_response(
            "Product updated, but facebook post could not be created",
            201,
          )
      }
    }
    Error(error) -> {
      logger.log_error(error)
      to_http_response(error)
    }
  }
}

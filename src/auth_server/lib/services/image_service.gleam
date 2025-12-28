import auth_server/lib/file/file
import auth_server/lib/user/types.{type User}
import auth_server/lib/utils/logger
import auth_server/web
import gleam/http
import gleam/http/request
import gleam/int
import gleam/result
import wisp

pub fn delete_image(
  req: request.Request(wisp.Connection),
  ctx: web.Context,
  user: User,
  image_id_str: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)

  let delete_image_result = {
    use image_id <- result.try(
      int.parse(image_id_str)
      |> result.replace_error("Invalid image id"),
    )

    file.delete_file(ctx.db, image_id, user)
  }

  case delete_image_result {
    Ok(_) -> wisp.json_response("Image deleted successfully", 200)
    Error("Invalid image id" as err) -> {
      logger.log_error(err)
      wisp.json_response("Invalid image id", 400)
    }
    Error("No image found with that ID" as err) -> {
      logger.log_error(err)
      wisp.json_response(err, 404)
    }
    Error(err) -> {
      logger.log_error(err)
      wisp.json_response(err, 500)
    }
  }
}

pub fn get_images(
  req: request.Request(wisp.Connection),
  ctx: web.Context,
  user: User,
) {
  wisp.json_response("images", 200)
}

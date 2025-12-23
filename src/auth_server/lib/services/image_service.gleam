import auth_server/lib/image/image
import auth_server/lib/user/types.{type User}
import auth_server/web
import gleam/http
import gleam/http/request
import gleam/int
import gleam/list
import gleam/result
import wisp

pub fn delete_image(
  req: request.Request(wisp.Connection),
  ctx: web.Context,
  user: User,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)
  let query_parameters = wisp.get_query(req)

  let delete_image_result = {
    use image_id_str <- result.try(
      list.key_find(query_parameters, "image_id")
      |> result.replace_error("No image id provided"),
    )

    use image_id <- result.try(
      int.parse(image_id_str)
      |> result.replace_error("Invalid image id"),
    )

    image.delete_image(ctx.db, image_id, user)
  }

  case delete_image_result {
    Ok(_) -> wisp.json_response("Image deleted successfully", 200)
    Error("No image id provided") ->
      wisp.json_response("No image id provided", 400)
    Error("Invalid image id") -> wisp.json_response("Invalid image id", 400)
    Error(err) -> wisp.json_response(err, 500)
  }
}

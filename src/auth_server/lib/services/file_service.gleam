import auth_server/lib/file/file
import auth_server/lib/file/transform as file_transform
import auth_server/lib/user/types.{type User}
import auth_server/lib/utils/logger
import auth_server/web
import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import wisp

pub fn delete_file(
  req: request.Request(wisp.Connection),
  ctx: web.Context,
  user: User,
  file_id_str: String,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Delete)

  let delete_file_result = {
    use file_id <- result.try(
      int.parse(file_id_str)
      |> result.replace_error("Invalid file id"),
    )

    file.delete_file(ctx.db, file_id, user)
  }

  case delete_file_result {
    Ok(_) -> wisp.json_response("File deleted successfully", 200)
    Error("Invalid file id" as err) -> {
      logger.log_error(err)
      wisp.json_response("Invalid file id", 400)
    }
    Error("No file found with that ID" as err) -> {
      logger.log_error(err)
      wisp.json_response(err, 404)
    }
    Error(err) -> {
      logger.log_error(err)
      wisp.json_response(err, 500)
    }
  }
}

pub fn get_files(
  req: request.Request(wisp.Connection),
  ctx: web.Context,
  user: User,
) {
  case file.get_files(db: ctx.db, file_types: [], user: user) {
    Ok(files) -> {
      files
      |> list.map(file_transform.select_files_rows_to_files)
      |> list.map(file_transform.file_to_json)
      |> json.array(of: fn(json_file) { json_file })
      |> json.to_string
      |> wisp.json_response(200)
    }
    Error(err) -> {
      logger.log_error(err)
      wisp.json_response(string.inspect(err), 500)
    }
  }
}

import auth_server/global_types
import auth_server/lib/models/file/file
import auth_server/lib/models/file/file_transform
import auth_server/lib/models/user/user_types.{type User}
import auth_server/lib/utils/logger
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
  ctx: global_types.Context,
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
  _req: request.Request(wisp.Connection),
  ctx: global_types.Context,
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

pub fn create_files(
  req: request.Request(wisp.Connection),
  ctx: global_types.Context,
  user: User,
) {
  use <- wisp.require_method(req, http.Post)
  use json_body <- wisp.require_json(req)

  case file.create_files(ctx.db, json_body, user) {
    Ok(message) -> wisp.json_response(message, 201)
    Error(error) -> {
      logger.log_error(error)
      wisp.json_response(error, 500)
    }
  }
}

import gleam/http
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/result
import handygleam/global_types
import handygleam/lib/models/error/app_error.{
  AppError, InvalidPayload, to_http_response,
}
import handygleam/lib/models/file/file
import handygleam/lib/models/file/file_transform
import handygleam/lib/models/user/user_types.{type User}
import handygleam/lib/utils/logger
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
      |> result.replace_error(AppError(
        error: InvalidPayload,
        message: "Invalid file id",
      )),
    )

    file.delete_file(ctx.db, file_id, user)
  }

  case delete_file_result {
    Ok(_) -> wisp.json_response("File deleted successfully", 200)
    Error(delete_file_error) -> {
      logger.log_error(delete_file_error)
      to_http_response(delete_file_error)
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
    Error(get_files_error) -> {
      logger.log_error(get_files_error)
      to_http_response(get_files_error)
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
    Error(create_file_error) -> {
      logger.log_error(create_file_error)
      to_http_response(create_file_error)
    }
  }
}

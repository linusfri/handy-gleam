import auth_server/lib/models/file/file_types.{
  type ContextType, type File, type FileType, type FileUploadRequest, File,
  FileUploadRequest,
}
import auth_server/lib/models/file_system/file_system
import auth_server/sql
import gleam/dynamic
import gleam/dynamic/decode
import gleam/json
import gleam/option

/// Converts SelectFileByIdRow to File
/// REFACTOR TO BE GENERIC
pub fn select_file_by_id_row_to_file(row: sql.SelectFileByIdRow) {
  File(
    id: option.Some(row.id),
    data: option.None,
    filename: row.filename,
    file_type: row.file_type,
    context_type: row.context_type,
    uri: option.Some(file_system.file_uri(
      row.filename,
      row.context_type,
      row.file_type,
    )),
  )
}

/// Converts SelectFilesRow to File
/// REFACTOR TO BE GENERIC
pub fn select_files_rows_to_files(row: sql.SelectFilesRow) {
  File(
    id: option.Some(row.id),
    data: option.None,
    filename: row.filename,
    file_type: row.file_type,
    context_type: row.context_type,
    uri: option.Some(file_system.file_uri(
      row.filename,
      row.context_type,
      row.file_type,
    )),
  )
}

pub fn file_type_enum_to_json(file_type_enum: FileType) -> json.Json {
  case file_type_enum {
    sql.Video -> json.string("video")
    sql.Image -> json.string("image")
    sql.Unknown -> json.string("unknown")
  }
}

pub fn context_type_enum_to_json(context_type_enum: ContextType) -> json.Json {
  case context_type_enum {
    sql.Misc -> json.string("misc")
    sql.Product -> json.string("product")
    sql.User -> json.string("user")
  }
}

pub fn context_type_decoder() -> decode.Decoder(sql.ContextTypeEnum) {
  use value <- decode.then(decode.string)
  case value {
    "product" -> decode.success(sql.Product)
    "user" -> decode.success(sql.User)
    "misc" -> decode.success(sql.Misc)
    _ -> decode.failure(sql.Misc, "ContextTypeEnum")
  }
}

pub fn file_type_decoder() -> decode.Decoder(FileType) {
  use variant <- decode.then(decode.string)
  case variant {
    "image" -> decode.success(sql.Image)
    "video" -> decode.success(sql.Video)
    _ -> decode.failure(sql.Unknown, expected: "FileType")
  }
}

pub fn file_to_json(file: File) -> json.Json {
  let File(id:, data:, filename:, file_type:, context_type:, uri:) = file
  json.object([
    #("id", case id {
      option.None -> json.null()
      option.Some(value) -> json.int(value)
    }),
    #("data", case data {
      option.None -> json.null()
      option.Some(value) -> json.string(value)
    }),
    #("filename", json.string(filename)),
    #("uri", case uri {
      option.Some(uri) -> json.string(uri)
      option.None -> json.null()
    }),
    #("file_type", file_type_enum_to_json(file_type)),
    #("context_type", context_type_enum_to_json(context_type)),
  ])
}

pub fn file_upload_request_to_json(
  file_upload_request: FileUploadRequest,
) -> json.Json {
  let FileUploadRequest(data:, filename:, filetype:, context:) =
    file_upload_request
  json.object([
    #("data", json.string(data)),
    #("filename", json.string(filename)),
    #("filetype", file_type_enum_to_json(filetype)),
    #("context", context_type_enum_to_json(context)),
  ])
}

pub fn file_upload_request_decoder() -> decode.Decoder(FileUploadRequest) {
  use data <- decode.field("data", decode.string)
  use filename <- decode.field("filename", decode.string)
  use filetype <- decode.field("filetype", file_type_decoder())
  use context <- decode.field("context", context_type_decoder())
  decode.success(FileUploadRequest(data:, filename:, filetype:, context:))
}

pub fn multiple_file_upload_request_decoder(
  files_upload_request: dynamic.Dynamic,
) {
  let multiple_file_upload_request_decoder = {
    use files <- decode.field(
      "files",
      decode.list(file_upload_request_decoder()),
    )

    decode.success(files)
  }

  decode.run(files_upload_request, multiple_file_upload_request_decoder)
}

import auth_server/sql
import gleam/dynamic/decode
import gleam/json

pub type FileType =
  sql.FileTypeEnum

pub fn file_type_enum_to_json(file_type_enum: FileType) -> json.Json {
  case file_type_enum {
    sql.Video -> json.string("video")
    sql.Image -> json.string("image")
    sql.Unknown -> json.string("unknown")
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

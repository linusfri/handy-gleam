import auth_server/config.{config}
import auth_server/lib/file/types.{type File}
import auth_server/lib/utils/logger
import auth_server/sql
import gleam/bit_array
import gleam/option.{Some}
import gleam/result
import gleam/string
import simplifile

pub fn save_base64_image(
  base64_string: String,
  output_path: String,
) -> Result(Nil, String) {
  // Remove data URL prefix if present (e.g., "data:image/png;base64,")
  let base64_data = case string.split(base64_string, ",") {
    [_prefix, data] -> data
    _ -> base64_string
  }

  case bit_array.base64_decode(base64_data) {
    Ok(image_bytes) -> {
      case simplifile.write_bits(to: output_path, bits: image_bytes) {
        Ok(_) -> Ok(Nil)
        Error(err) -> {
          logger.log_error_with_context("save_base64_image:write_bits", err)
          Error("Failed to write file: " <> string.inspect(err))
        }
      }
    }
    Error(err) -> {
      logger.log_error_with_context("save_base64_image:base64_decode", err)
      Error("Invalid base64 string")
    }
  }
}

/// Deletes an image file from disk
/// 
/// # Examples
/// ```gleam
/// delete_image(file_of_type_file)
/// ```
pub fn delete_file(file: File) -> Result(Nil, String) {
  case simplifile.delete(file_url_from_file(file)) {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error("Failed to delete image: " <> string.inspect(err))
  }
}

/// Creates an image file on disk
/// 
/// # Examples
/// ```gleam
/// delete_image(file_of_type_file)
/// ```
pub fn create_file(file: File) {
  let directory =
    case file.context_type {
      sql.Product -> "product"
      sql.User -> "user"
      sql.Misc -> "misc"
    }
    <> "/"
    <> case file.file_type {
      sql.Image -> "image"
      sql.Video -> "video"
      sql.Unknown -> "unknown"
    }
  let upload_path = config().static_directory <> "/" <> directory

  case file.data {
    Some(base64_data) if base64_data != "" -> {
      // Ensure directory exists
      let _ = simplifile.create_directory_all(upload_path)
      let clean_name = string.replace(file.filename, " ", "_")

      save_base64_image(base64_data, upload_path <> "/" <> clean_name)
      |> result.replace(clean_name)
    }
    _ -> Error("Could not create file")
  }
}

/// Get file url for the file name in specified directory
pub fn file_url_from_file(file: File) -> String {
  let static_files_directory = config().static_directory

  let context_dir = case file.context_type {
    sql.Product -> "product"
    sql.User -> "user"
    sql.Misc -> "misc"
  }

  let file_type = file.file_type

  static_files_directory
  <> "/"
  <> context_dir
  <> "/"
  <> case file_type {
    sql.Image -> "image"
    sql.Video -> "video"
    sql.Unknown -> "unknown"
  }
  <> "/"
  <> file.filename
}

pub fn file_url(
  filename: String,
  context_type: types.ContextType,
  file_type: types.FileType,
) {
  let static_files_directory = config().static_directory

  let context_dir = case context_type {
    sql.Product -> "product"
    sql.User -> "user"
    sql.Misc -> "misc"
  }

  static_files_directory
  <> "/"
  <> context_dir
  <> "/"
  <> case file_type {
    sql.Image -> "image"
    sql.Video -> "video"
    sql.Unknown -> "unknown"
  }
  <> "/"
  <> filename
}

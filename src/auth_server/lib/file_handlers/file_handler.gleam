import auth_server/config.{config}
import gleam/bit_array
import gleam/option.{type Option, Some}
import gleam/result
import gleam/string
import simplifile
import youid/uuid

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
        Error(err) -> Error("Failed to write file: " <> string.inspect(err))
      }
    }
    Error(_) -> Error("Invalid base64 string")
  }
}

/// Deletes an image file from disk
/// 
/// # Examples
/// ```gleam
/// delete_image("product_abc_123.png", "products")
/// delete_image("avatar_xyz_456.png", "users")
/// ```
pub fn delete_file(
  filename: String,
  directory: Option(String),
) -> Result(Nil, String) {
  let static_files_path =
    config().static_directory <> "/" <> option.unwrap(directory, "")
  let file_path = static_files_path <> "/" <> filename

  case simplifile.delete(file_path) {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error("Failed to delete image: " <> string.inspect(err))
  }
}

/// Creates an image file on disk
/// 
/// # Examples
/// ```gleam
/// create_image_file("product_abc_123.png", Some("base64"), "products")
/// create_image_file("avatar_xyz_456.png", Some("base64"), "products")
/// ```
pub fn create_file(
  filename filename: String,
  base64_encoded_file base64_encoded_file: Option(String),
  directory directory: String,
) {
  let static_directory_path = config().static_directory <> "/" <> directory

  case base64_encoded_file {
    Some(base64_image) if base64_image != "" -> {
      // Ensure directory exists
      let _ = simplifile.create_directory_all(static_directory_path)
      let clean_name = string.replace(filename, " ", "_")
      let upload_path = static_directory_path <> "/" <> clean_name

      save_base64_image(base64_image, upload_path)
      |> result.replace(filename)
    }
    _ -> Error("Could not create file")
  }
}

/// Get image url for the file name in specified directory
pub fn file_url(filename: String, directory_path: String) -> String {
  let static_files_directory = config().static_directory
  static_files_directory <> "/" <> directory_path <> "/" <> filename
}

pub fn find_and_delete_file(
  filename filename: String,
  directory directory: String,
) -> Result(Nil, String) {
  let static_files_directory = config().static_directory
  let full_directory_path = static_files_directory <> "/" <> directory

  use entries <- result.try(
    simplifile.read_directory(full_directory_path)
    |> result.map_error(string.inspect),
  )

  // Try to delete the file if it exists in current directory
  let file_path = full_directory_path <> "/" <> filename
  case simplifile.delete(file_path) {
    Ok(_) -> Ok(Nil)
    Error(_) -> search_subdirectories(entries, full_directory_path, filename)
  }
}

pub fn search_subdirectories(
  entries: List(String),
  parent_dir: String,
  filename: String,
) -> Result(Nil, String) {
  case entries {
    [] -> Error("Image file not found: " <> filename)
    [entry, ..rest] -> {
      let entry_path = parent_dir <> "/" <> entry

      case simplifile.is_directory(entry_path) {
        Ok(True) -> {
          // Extract just the relative path from static directory
          let static_dir = config().static_directory <> "/"
          let relative_path = case string.split(entry_path, static_dir) {
            [_, rest] -> rest
            _ -> entry_path
          }

          case
            find_and_delete_file(filename: filename, directory: relative_path)
          {
            Ok(_) -> Ok(Nil)
            Error(_) -> search_subdirectories(rest, parent_dir, filename)
          }
        }
        _ -> search_subdirectories(rest, parent_dir, filename)
      }
    }
  }
}

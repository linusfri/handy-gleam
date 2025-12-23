import gleam/bit_array
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
        Error(err) -> Error("Failed to write file: " <> string.inspect(err))
      }
    }
    Error(_) -> Error("Invalid base64 string")
  }
}

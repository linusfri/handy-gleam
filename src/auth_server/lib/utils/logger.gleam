import gleam/string
import simplifile

const log_file = "logs/errors.log"

/// Logs an error to a file with a timestamp
pub fn log_error(error: a) -> Nil {
  let error_message = "ERROR: " <> string.inspect(error) <> "\n"

  // Ensure logs directory exists and append to file
  let _ = simplifile.create_directory_all("logs")
  let _ = simplifile.append(log_file, error_message)

  Nil
}

/// Logs an error with a context message
pub fn log_error_with_context(context: String, error: a) -> Nil {
  let error_message = context <> " | ERROR: " <> string.inspect(error) <> "\n"

  // Ensure logs directory exists and append to file
  let _ = simplifile.create_directory_all("logs")
  let _ = simplifile.append(log_file, error_message)

  Nil
}

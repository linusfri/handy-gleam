import auth_server/lib/file/types as file_types
import auth_server/lib/file_handlers/file_handler
import auth_server/lib/user/types.{type User}
import auth_server/lib/utils/logger
import auth_server/sql
import gleam/option
import gleam/result
import gleam/string
import pog

/// Deletes an image from database and disk
pub fn delete_file(
  db: pog.Connection,
  file_id: Int,
  user: User,
) -> Result(Nil, String) {
  use deleted_row <- result.try(
    pog.transaction(db, fn(tx) {
      use select_file_result <- result.try(
        sql.select_file_by_id(tx, file_id)
        |> result.map_error(fn(err) {
          logger.log_error_with_context("delete_file:select_file_by_id", err)
          "Failed to get image: " <> string.inspect(err)
        }),
      )

      use file_sql_row <- result.try(case select_file_result.rows {
        [first, ..] -> Ok(first)
        [] -> Error("No image found with that ID")
      })

      // Delete from DB (only if user has access to the product)
      use _ <- result.try(
        sql.delete_file_by_id(tx, file_id, user.groups)
        |> result.map_error(fn(err) {
          logger.log_error_with_context("delete_file:delete_file_by_id", err)
          "DB deletion failed: " <> string.inspect(err)
        }),
      )

      Ok(file_sql_row)
    })
    |> result.map_error(fn(err) {
      logger.log_error_with_context("delete_file:transaction", err)
      "Transaction failed: " <> string.inspect(err)
    }),
  )

  let file = select_file_by_id_row_to_file(deleted_row)

  // Delete from disk
  use _ <- result.try(
    file_handler.delete_file(file)
    |> result.map_error(fn(err) {
      logger.log_error_with_context(
        "filehandler:delete_file",
        string.inspect(err),
      )
      "Failed to delete file: " <> err
    }),
  )

  Ok(Nil)
}

/// Converts SelectFileByIdRow to File
pub fn select_file_by_id_row_to_file(row: sql.SelectFileByIdRow) {
  file_types.File(
    id: option.Some(row.id),
    data: option.None,
    filename: row.filename,
    file_type: row.file_type,
    context_type: row.context_type,
  )
}

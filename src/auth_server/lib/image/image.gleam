import auth_server/lib/file_handlers/file_handler
import auth_server/lib/user/types.{type User}
import auth_server/sql
import gleam/result
import gleam/string
import pog

/// Deletes an image from database and disk
pub fn delete_image(
  db: pog.Connection,
  image_id: Int,
  user: User,
) -> Result(Nil, String) {
  // First, get the filename from DB
  use image_result <- result.try(
    sql.select_image_by_id(db, image_id)
    |> result.map_error(fn(err) {
      "Failed to get image: " <> string.inspect(err)
    }),
  )

  // Extract filename from first row
  use image_row <- result.try(case image_result.rows {
    [first, ..] -> Ok(first)
    [] -> Error("No image found with that ID")
  })

  // Delete from DB (only if user has access to the product)
  use _ <- result.try(
    sql.delete_image_by_id(db, image_id, user.groups)
    |> result.map_error(fn(err) {
      "DB deletion failed: " <> string.inspect(err)
    }),
  )

  // Delete from disk
  use _ <- result.try(file_handler.find_and_delete_file(
    filename: image_row.filename,
    directory: "images",
  ))

  Ok(Nil)
}

import auth_server/lib/file/transform as file_transform
import auth_server/lib/file/types as file_types
import auth_server/lib/file_system/file_system
import auth_server/lib/user/types.{type User}
import auth_server/sql
import gleam/dynamic
import gleam/list
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
        sql.select_file_by_id(tx, file_id, user.groups)
        |> result.map_error(fn(err) {
          "file:delete_file:select_file_by_id | " <> string.inspect(err)
        }),
      )

      use file_sql_row <- result.try(case select_file_result.rows {
        [first, ..] -> Ok(first)
        [] -> Error("No image found with that ID")
      })

      // Delete from DB (only if user has access to the file)
      use _ <- result.try(
        sql.delete_file_by_id(tx, file_id, user.groups)
        |> result.map_error(fn(err) {
          "file:delete_file:delete_file_by_id | " <> string.inspect(err)
        }),
      )

      Ok(file_sql_row)
    })
    |> result.map_error(fn(err) {
      "file:delete_file:pog.transaction | " <> string.inspect(err)
    }),
  )

  let file = file_transform.select_file_by_id_row_to_file(deleted_row)

  // Delete from disk
  use _ <- result.try(
    file_system.delete_file(file)
    |> result.map_error(fn(err) { "file:filehandler:delete_file " <> err }),
  )

  Ok(Nil)
}

pub fn get_files(
  db db: pog.Connection,
  file_types file_types: List(String),
  user user: User,
) {
  use get_files_result <- result.try(
    pog.transaction(db, fn(tx) { sql.select_files(tx, user.groups) })
    |> result.map_error(fn(err) { "file:get_files | " <> string.inspect(err) }),
  )

  Ok(get_files_result.rows)
}

pub fn create_files(
  db db: pog.Connection,
  files files_data: dynamic.Dynamic,
  user user: User,
) {
  use files_upload_request <- result.try(
    file_transform.multiple_file_upload_request_decoder(files_data)
    |> result.map_error(fn(err) {
      "file:create_files | " <> string.inspect(err)
    }),
  )

  let files =
    list.map(files_upload_request, fn(file) {
      file_types.File(
        id: option.None,
        data: option.Some(file.data),
        filename: file.filename,
        file_type: file.mimetype,
        context_type: file.context,
        uri: option.None,
      )
    })

  // Create the "physical" files
  use _ <- result.try(
    list.try_map(files, fn(file) { file_system.create_file(file) })
    |> result.map_error(fn(err) {
      "file:create_files:create_file | " <> string.inspect(err)
    }),
  )

  let #(filenames, filetypes, contexts) =
    list.fold(files, #([], [], []), fn(acc, file) {
      let #(names, types, ctxs) = acc
      #([file.filename, ..names], [file.file_type, ..types], [
        file.context_type,
        ..ctxs
      ])
    })

  // Create the files in database
  use _ <- result.try(
    pog.transaction(db, fn(tx) {
      use created_files_result <- result.try(
        sql.create_files(tx, filenames, filetypes, contexts)
        |> result.map_error(fn(err) {
          "file:create_files:sql.create_files | " <> string.inspect(err)
        }),
      )

      let created_file_ids =
        list.map(created_files_result.rows, fn(created_file) { created_file.id })

      use created_files_user_groups <- result.try(
        sql.create_files_user_groups(tx, created_file_ids, user.groups)
        |> result.map_error(fn(err) {
          "file:create_files:sql.create_files | " <> string.inspect(err)
        }),
      )

      Ok(created_files_user_groups)
    })
    |> result.map_error(fn(err) { string.inspect(err) }),
  )

  Ok("Files created")
}

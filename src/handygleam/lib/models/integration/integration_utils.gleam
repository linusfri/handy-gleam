import gleam/int
import gleam/list
import gleam/result
import gleam/string
import handygleam/global_types
import handygleam/lib/models/error/app_error.{
  type AppError, AppError, DbError, NotFound, from_transaction,
}
import handygleam/lib/models/integration/integration_types.{type FacebookPage}
import handygleam/lib/models/user/user_types.{type User}
import handygleam/sql
import pog

pub fn get_integration_token(
  ctx: global_types.Context,
  user: User,
  integration: sql.IntegrationPlatform,
) {
  use integration_token_db_results <- result.try(
    pog.transaction(ctx.db, fn(tx) {
      use token <- result.try(
        sql.select_user_integration_token(tx, user.sub, integration)
        |> result.map_error(fn(error) {
          AppError(error: DbError, message: string.inspect(error))
        }),
      )

      Ok(token)
    })
    |> result.map_error(from_transaction),
  )

  case integration_token_db_results.rows {
    [] -> Error(AppError(error: NotFound, message: "No tokens found"))
    [first_row, ..] -> Ok(first_row)
  }
}

pub fn save_platform_resources(
  ctx: global_types.Context,
  user: User,
  platform: sql.IntegrationPlatform,
  pages: List(FacebookPage),
) -> Result(List(sql.CreateOrUpdatePlatformResourcesRow), AppError) {
  let #(external_ids, resource_names, resource_tokens) =
    list.fold(pages, #([], [], []), fn(acc, page) {
      let #(external_ids, resource_names, resource_tokens) = acc
      #([page.id, ..external_ids], [page.name, ..resource_names], [
        page.access_token,
        ..resource_tokens
      ])
    })

  use save_result <- result.try(
    pog.transaction(ctx.db, fn(tx) {
      use saved <- result.try(
        sql.create_or_update_platform_resources(
          tx,
          user.sub,
          platform,
          sql.Page,
          external_ids,
          resource_names,
          resource_tokens,
        )
        |> result.map_error(fn(error) {
          AppError(error: DbError, message: string.inspect(error))
        }),
      )

      Ok(saved)
    })
    |> result.map_error(from_transaction),
  )

  case save_result.rows {
    [] -> Error(AppError(error: DbError, message: "Failed to save resources"))
    rows -> Ok(rows)
  }
}

pub fn get_platform_resource(
  ctx: global_types.Context,
  user: User,
  platform: sql.IntegrationPlatform,
  external_id: String,
) -> Result(sql.SelectPlatformResourceRow, AppError) {
  use resource_result <- result.try(
    pog.transaction(ctx.db, fn(tx) {
      use resource <- result.try(
        sql.select_platform_resource(tx, user.sub, platform, external_id)
        |> result.map_error(fn(error) {
          AppError(error: DbError, message: string.inspect(error))
        }),
      )

      Ok(resource)
    })
    |> result.map_error(from_transaction),
  )

  case resource_result.rows {
    [] ->
      Error(AppError(
        error: NotFound,
        message: "Resource not found for external_id: " <> external_id,
      ))
    [first_row, ..] -> Ok(first_row)
  }
}

pub fn build_facbook_media_query(media: List(String)) -> List(#(String, String)) {
  media
  |> list.index_map(fn(id, index) {
    #(
      "attached_media[" <> int.to_string(index) <> "]",
      "{\"media_fbid\":\"" <> id <> "\"}",
    )
  })
}

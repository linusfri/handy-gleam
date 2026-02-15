import auth_server/global_types
import auth_server/lib/models/integration/integration_types.{type FacebookPage}
import auth_server/lib/models/user/user_types.{type User}
import auth_server/sql
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import pog

pub fn get_integration_token(
  ctx: global_types.Context,
  user: User,
  integration: sql.IntegrationPlatform,
) {
  use integration_token_db_results <- result.try(
    pog.transaction(ctx.db, fn(tx) {
      sql.select_user_integration_token(tx, user.sub, integration)
    })
    |> result.map_error(fn(error) { string.inspect(error) }),
  )

  case integration_token_db_results.rows {
    [] -> Error("No tokens found")
    [first_row, ..] -> Ok(first_row)
  }
}

pub fn save_platform_resources(
  ctx: global_types.Context,
  user: User,
  platform: sql.IntegrationPlatform,
  pages: List(FacebookPage),
) -> Result(List(sql.CreateOrUpdatePlatformResourcesRow), String) {
  let external_ids = list.map(pages, fn(page) { page.id })
  let resource_names = list.map(pages, fn(page) { page.name })
  let resource_tokens = list.map(pages, fn(page) { page.access_token })

  use save_result <- result.try(
    pog.transaction(ctx.db, fn(tx) {
      sql.create_or_update_platform_resources(
        tx,
        user.sub,
        platform,
        sql.Page,
        external_ids,
        resource_names,
        resource_tokens,
      )
    })
    |> result.map_error(fn(error) { string.inspect(error) }),
  )

  case save_result.rows {
    [] -> Error("Failed to save resources")
    rows -> Ok(rows)
  }
}

pub fn get_platform_resource(
  ctx: global_types.Context,
  user: User,
  platform: sql.IntegrationPlatform,
  external_id: String,
) -> Result(sql.SelectPlatformResourceRow, String) {
  use resource_result <- result.try(
    pog.transaction(ctx.db, fn(tx) {
      sql.select_platform_resource(tx, user.sub, platform, external_id)
    })
    |> result.map_error(fn(error) { string.inspect(error) }),
  )

  case resource_result.rows {
    [] -> Error("Resource not found for external_id: " <> external_id)
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

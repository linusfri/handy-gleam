import auth_server/lib/user/types.{type User}
import auth_server/sql
import auth_server/types as base_types
import gleam/result
import gleam/string
import pog

pub fn get_integration_token(
  ctx: base_types.Context,
  user: User,
  integration: sql.IntegrationPlatform,
) {
  use db_results <- result.try(
    pog.transaction(ctx.db, fn(tx) {
      sql.select_user_integration_token(tx, user.sub, integration)
    })
    |> result.map_error(fn(error) { string.inspect(error) }),
  )

  case db_results.rows {
    [] -> Error("No rows found")
    [first_row, ..] -> Ok(first_row)
  }
}

import gleam/http/request
import gleam/json
import gleam/list
import gleam/result
import handygleam/global_types
import handygleam/lib/models/auth/auth_utils
import handygleam/lib/models/error/app_error.{
  AppError, DbError, from_transaction, to_http_response,
}
import handygleam/lib/models/integration/facebook_instagram
import handygleam/lib/models/integration/integration_transform
import handygleam/lib/models/user/user
import handygleam/lib/models/user/user_transform
import handygleam/lib/models/user/user_types.{type User}
import handygleam/lib/utils/logger
import handygleam/sql
import pog
import wisp

pub fn initiate_facebook_login(req: request.Request(wisp.Connection)) {
  let user_token = auth_utils.get_session_token(req)

  case facebook_instagram.initiate_login(req) {
    Ok(redirect_url) -> {
      wisp.json_response(
        json.to_string(
          json.object([
            #("redirect_url", json.string(redirect_url)),
            #("fb_user_token", json.string(user_token)),
          ]),
        ),
        200,
      )
    }
    Error(error) -> to_http_response(error)
  }
}

pub fn request_long_lived_facebook_token(
  req: request.Request(wisp.Connection),
  ctx: global_types.Context,
) {
  let oauth_code =
    list.key_find(wisp.get_query(req), "code") |> result.unwrap("")

  // Unsafe but i can't fucking stand this
  let token = list.key_find(wisp.get_query(req), "state") |> result.unwrap("")

  let response = {
    use user <- result.try(
      user.get_session_user_by_token(token)
      |> result.map_error(fn(err) {
        logger.log_error_with_context(
          "integration_service:request_long_lived_facebook_token",
          err,
        )
        err
      }),
    )

    use facebook_token <- result.try(
      facebook_instagram.exchange_code_for_token(oauth_code)
      |> result.map_error(fn(err) {
        logger.log_error_with_context(
          "integration_service:request_long_lived_facebook_token",
          err,
        )
        err
      }),
    )

    use _ <- result.try(
      pog.transaction(ctx.db, fn(tx) {
        sql.create_user_integration_token(
          tx,
          user.sub,
          sql.Facebook,
          facebook_token.access_token,
          facebook_token.token_type,
        )
        |> result.map_error(fn(error) {
          logger.log_error_with_context(
            "integration_service:request_long_lived_facebook_token",
            error,
          )
          AppError(
            error: DbError,
            message: "Could not create facebook token for user in database",
          )
        })
      })
      |> result.map_error(from_transaction),
    )

    Ok(wisp.html_response(
      "<html>
        <style>
          body {
            padding: 16px;
            display: flex;
            flex-grow: 1;
            align-items: center;
            justify-content: center;
          }

          h1 {
            font-size: 4.8rem;
            text-align: center;
            color: #009966;
          }
        </style>
        <body>
          <h1>Successfully connected Facebook!</h1>
        </body>
      </html>
      ",
      200,
    ))
  }

  case response {
    Ok(response) -> response
    Error(error_response) -> to_http_response(error_response)
  }
}

pub fn get_facebook_user(
  ctx: global_types.Context,
  user: User,
  integration: sql.IntegrationPlatform,
) {
  case facebook_instagram.get_facebook_user(ctx, user, integration) {
    Ok(facebook_user) ->
      wisp.json_response(
        json.to_string(user_transform.facebook_user_to_json(facebook_user)),
        200,
      )
    Error(error) -> to_http_response(error)
  }
}

pub fn get_current_facebook_user_pages(
  ctx: global_types.Context,
  user: User,
  integration: sql.IntegrationPlatform,
) {
  case
    facebook_instagram.fetch_and_cache_facebook_pages(ctx, user, integration)
  {
    Ok(pages) ->
      wisp.json_response(
        json.to_string(integration_transform.facebook_pages_response_to_json(
          pages,
        )),
        200,
      )
    Error(error) -> to_http_response(error)
  }
}

pub fn sync_product_to_facebook(ctx, user, facebook_product) {
  let facebook_post_created =
    facebook_instagram.update_or_create_post_on_page(
      ctx,
      user,
      sql.Facebook,
      facebook_product,
    )

  result.is_error(facebook_post_created)
}

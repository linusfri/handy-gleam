import auth_server/lib/auth/auth_utils
import auth_server/lib/integration/facebook_instagram
import auth_server/lib/user/transform as user_transform
import auth_server/lib/user/types.{type User}
import auth_server/lib/user/user
import auth_server/lib/utils/logger
import auth_server/sql
import auth_server/types as base_types
import gleam/http/request
import gleam/json
import gleam/list
import gleam/result
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
    Error(error) -> wisp.json_response(error, 500)
  }
}

pub fn request_long_lived_facebook_token(
  req: request.Request(wisp.Connection),
  ctx: base_types.Context,
) {
  let code = list.key_find(wisp.get_query(req), "code") |> result.unwrap("")

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
        wisp.json_response("Could not get session user", 500)
      }),
    )

    use facebook_token <- result.try(
      facebook_instagram.exchange_code_for_token(code)
      |> result.map_error(fn(err) {
        logger.log_error_with_context(
          "integration_service:request_long_lived_facebook_token",
          err,
        )
        wisp.json_response("Could not get facebook long lived token", 500)
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
      })
      |> result.map_error(fn(error) {
        logger.log_error_with_context(
          "integration_service:request_long_lived_facebook_token",
          error,
        )
        wisp.json_response("Could not log in to facebook", 500)
      }),
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
    Error(error_response) -> error_response
  }
}

pub fn get_facebook_user(
  ctx: base_types.Context,
  user: User,
  integration: sql.IntegrationPlatform,
) {
  case facebook_instagram.get_facebook_user(ctx, user, integration) {
    Ok(facebook_user) ->
      wisp.json_response(
        json.to_string(user_transform.facebook_user_to_json(facebook_user)),
        200,
      )
    Error(message) -> wisp.json_response(message, 500)
  }
}

import auth_server/config.{config}
import auth_server/global_types
import auth_server/lib/models/auth/auth_utils
import auth_server/lib/models/integration/integration_transform
import auth_server/lib/models/integration/integration_types
import auth_server/lib/models/integration/integration_utils
import auth_server/lib/models/user/user_transform
import auth_server/lib/models/user/user_types
import auth_server/lib/utils/api_client
import auth_server/lib/utils/logger
import auth_server/sql
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import wisp

pub fn initiate_login(
  req: request.Request(wisp.Connection),
) -> Result(String, String) {
  let token = auth_utils.get_session_token(req)

  let request =
    request.Request(
      method: http.Get,
      headers: [],
      body: "",
      scheme: http.Https,
      host: "www.facebook.com",
      port: None,
      path: "/dialog/oauth",
      query: None,
    )
    |> request.set_query([
      #("client_id", config().facebook_app_id),
      #("redirect_uri", config().facebook_redirect_uri),
      #("response_type", "code"),
      #("state", token),
      #(
        "scope",
        "pages_show_list,business_management,instagram_basic,instagram_manage_comments,instagram_content_publish,instagram_manage_messages,pages_read_engagement,pages_manage_metadata,pages_read_user_content,pages_manage_posts,pages_manage_engagement",
      ),
    ])

  use res <- result.try(api_client.send_request(request))

  case res.status {
    status if status > 300 && status < 400 -> {
      list.key_find(res.headers, "location")
      |> result.map_error(fn(_) {
        "Did not get a correct redirect response from facebook"
      })
    }
    _ -> Error("Unexpected response: " <> res.body)
  }
}

pub fn exchange_code_for_token(
  code: String,
) -> Result(integration_types.FacebookToken, String) {
  let token_request =
    request.Request(
      method: http.Get,
      headers: [],
      body: "",
      scheme: http.Https,
      host: config().facebook_base_url,
      port: None,
      path: "/oauth/access_token",
      query: None,
    )
    |> request.set_query([
      #("client_id", config().facebook_app_id),
      #("client_secret", config().facebook_app_secret),
      #("redirect_uri", config().facebook_redirect_uri),
      #("fields", "expires_in,access_token,token_type"),
      #("code", code),
    ])

  use response <- result.try(api_client.send_request(token_request))

  case response.status {
    status if status >= 200 && status < 300 -> {
      use json_data <- result.try(
        json.parse(response.body, decode.dynamic)
        |> result.map_error(fn(err) {
          logger.log_error(err)
          "Failed to parse Facebook token response"
        }),
      )

      integration_transform.facebook_token_decoder(json_data)
      |> result.map_error(fn(err) {
        logger.log_error_with_context(
          "facebook_instagram:exchange_code_for_token",
          err,
        )
        "Failed to decode Facebook token"
      })
    }
    _ -> Error("Facebook API error: " <> response.body)
  }
}

pub fn get_facebook_user(
  ctx: global_types.Context,
  user: user_types.User,
  integration: sql.IntegrationPlatform,
) {
  use facebook_token <- result.try(
    integration_utils.get_integration_token(ctx, user, integration)
    |> result.map_error(fn(error) {
      logger.log_error_with_context(
        "integration_service:get_facebook_user",
        error,
      )
      "Could not get facebook token from database."
    }),
  )

  let user_request =
    request.Request(
      method: http.Get,
      headers: [],
      body: "",
      scheme: http.Https,
      host: config().facebook_base_url,
      port: None,
      path: "/me",
      query: Some("access_token=" <> facebook_token.access_token),
    )

  let facebook_user = {
    use user_response <- result.try(case api_client.send_request(user_request) {
      Ok(response) -> Ok(response)
      Error(error_response) -> Error(error_response <> error_response)
    })

    use dynamic_user <- result.try(
      json.parse(user_response.body, decode.dynamic)
      |> result.map_error(fn(error) {
        logger.log_error_with_context(
          "facebook_instagram:get_facebook_user",
          error,
        )
        "Could not get user from facebook api response"
      }),
    )

    use user <- result.try(
      user_transform.facebook_user_decoder(dynamic_user)
      |> result.map_error(fn(error) {
        logger.log_error_with_context(
          "facebook_instagram:get_facebook_user",
          error,
        )
        "Failed to decode facebook user from reponse"
      }),
    )

    Ok(user)
  }

  case facebook_user {
    Ok(facebook_user) -> Ok(facebook_user)
    Error(error) -> Error(error)
  }
}

pub fn get_current_facebook_user_pages(
  ctx: global_types.Context,
  user: user_types.User,
  integration: sql.IntegrationPlatform,
) -> Result(integration_types.FacebookPagesResponse, String) {
  use facebook_token <- result.try(
    integration_utils.get_integration_token(ctx, user, integration)
    |> result.map_error(fn(error) {
      logger.log_error_with_context(
        "facebook_instagram:get_current_facebook_user_pages",
        error,
      )
      "Could not get facebook token from database."
    }),
  )

  let user_pages_request =
    request.Request(
      method: http.Get,
      headers: [],
      body: "",
      scheme: http.Https,
      host: config().facebook_base_url,
      port: None,
      path: "/me/accounts",
      query: Some("access_token=" <> facebook_token.access_token),
    )

  use user_pages_response <- result.try(
    case api_client.send_request(user_pages_request) {
      Ok(response) -> Ok(response)
      Error(error_response) -> Error(error_response <> error_response)
    },
  )

  use dynamic_pages <- result.try(
    json.parse(user_pages_response.body, decode.dynamic)
    |> result.map_error(fn(error) {
      logger.log_error_with_context(
        "facebook_instagram:get_current_facebook_user_pages",
        error,
      )
      "Could not parse facebook pages response"
    }),
  )

  integration_transform.facebook_pages_response_decoder(dynamic_pages)
  |> result.map_error(fn(error) {
    logger.log_error_with_context(
      "facebook_instagram:get_current_facebook_user_pages",
      error,
    )
    "Failed to decode facebook pages from response"
  })
}

pub fn fetch_and_cache_facebook_pages(
  ctx: global_types.Context,
  user: user_types.User,
  integration: sql.IntegrationPlatform,
) -> Result(integration_types.FacebookPagesResponse, String) {
  use pages_response <- result.try(get_current_facebook_user_pages(
    ctx,
    user,
    integration,
  ))

  use _saved_resources <- result.try(
    integration_utils.save_platform_resources(
      ctx,
      user,
      integration,
      pages_response.data,
    )
    |> result.map_error(fn(error) {
      logger.log_error_with_context(
        "facebook_instagram:fetch_and_cache_facebook_pages",
        error,
      )
      "Failed to cache page resources in database"
    }),
  )

  Ok(pages_response)
}

pub fn get_page_token(
  ctx: global_types.Context,
  user: user_types.User,
  integration: sql.IntegrationPlatform,
  page_id: String,
) -> Result(String, String) {
  use resource <- result.try(
    integration_utils.get_platform_resource(ctx, user, integration, page_id)
    |> result.map_error(fn(error) {
      logger.log_error_with_context("facebook_instagram:get_page_token", error)
      error
    }),
  )

  case resource.resource_token {
    Some(token) -> Ok(token)
    None -> Error("Page token not found for page_id: " <> page_id)
  }
}

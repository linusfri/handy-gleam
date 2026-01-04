import auth_server/config.{config}
import auth_server/lib/auth/auth_utils
import auth_server/lib/integration/transform
import auth_server/lib/integration/types
import auth_server/lib/utils/api_client
import auth_server/lib/utils/logger
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option.{None}
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
        "pages_show_list,business_management,instagram_basic,instagram_manage_comments,instagram_content_publish,instagram_manage_messages",
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
) -> Result(types.FacebookToken, String) {
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

      transform.facebook_token_decoder(json_data)
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

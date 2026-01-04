import auth_server/config.{config}
import auth_server/lib/user/types.{type User}
import auth_server/lib/utils/api_client
import gleam/http
import gleam/http/request
import gleam/option.{None, Some}
import wisp

pub fn request_short_lived_token(
  req: request.Request(wisp.Connection),
  user: User,
) {
  let request =
    request.Request(
      method: http.Get,
      headers: [],
      body: "",
      scheme: http.Https,
      host: config().facebook_base_url,
      port: None,
      path: "/dialog/oauth",
      query: None,
    )
    |> request.set_query([
      #("client_id", config().facebook_app_id),
      #("redirect_uri", config().facebook_redirect_uri),
      #("state", config().facebook_state_param),
      #("response_type", "token"),
      #(
        "scope",
        "pages_show_list,business_management,instagram_basic,instagram_manage_comments,instagram_content_publish,instagram_manage_messages",
      ),
    ])

  api_client.send_request(request)
}

pub fn request_long_lived_token(
  req: request.Request(wisp.Connection),
  user: User,
) {
  todo
}

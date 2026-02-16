import gleam/dynamic/decode
import gleam/http/request as http_request
import gleam/json
import gleam/result
import glow_auth.{type Client, Client}
import glow_auth/token_request.{
  DefaultScope, RequestBody, client_credentials, refresh as refresh_credentials,
}
import glow_auth/uri/uri_builder.{RelativePath}
import handygleam/lib/models/auth/auth_transform
import handygleam/lib/models/auth/auth_types.{
  type LoginFormData, type RefreshTokenRequest, LoginResponse,
}
import handygleam/lib/models/auth/auth_utils
import handygleam/lib/services/user_service
import handygleam/lib/utils/api_client
import handygleam/lib/utils/logger
import wisp

fn create_client(client_id: String) -> Client(body) {
  let site = auth_utils.get_default_auth_uri()

  Client(id: client_id, secret: "None", site: site)
}

fn build_refresh_request(refresh_token_request: RefreshTokenRequest) {
  let client = create_client(refresh_token_request.client_id)
  let token_endpoint = RelativePath("token")

  refresh_credentials(
    client,
    token_endpoint,
    refresh_token_request.refresh_token,
  )
}

fn request_token(token_request: http_request.Request(String)) {
  let token = {
    use token_response <- result.try(api_client.send_request(token_request))
    use token_data <- result.try(
      json.parse(token_response.body, decode.dynamic)
      |> result.map_error(fn(err) {
        logger.log_error_with_context("oauth:request_token", err)
        "Failed to turn token into dynamic data"
      }),
    )

    use decoded_token <- result.try(
      auth_transform.token_response_decoder(token_data)
      |> result.map_error(fn(err) {
        logger.log_error_with_context("oauth:request_token", err)
        "Failed to decode token"
      }),
    )

    Ok(decoded_token)
  }

  case token {
    Ok(token) -> Ok(token)
    Error(message) -> Error(wisp.json_response(message, 500))
  }
}

pub fn build_refresh_response(refresh_token_request: RefreshTokenRequest) {
  let refresh_token_request = build_refresh_request(refresh_token_request)

  let token_response = request_token(refresh_token_request)

  use token <- result.try(token_response)

  let json_token = auth_transform.token_response_encoder(token)
  Ok(wisp.json_response(json.to_string(json_token), 200))
}

fn build_login_request(
  login_form_data: LoginFormData,
) -> http_request.Request(String) {
  let client = create_client(login_form_data.client_id)
  let token_endpoint = RelativePath("token")
  let request_body =
    auth_utils.build_url_encoded_request_body(login_form_data.body)

  client_credentials(client, token_endpoint, RequestBody, DefaultScope)
  |> http_request.set_body(request_body)
}

pub fn build_login_response(form_data: LoginFormData) {
  let login_request = build_login_request(form_data)

  let token_response = request_token(login_request)

  use token <- result.try(token_response)

  case user_service.request_get_user(token.access_token) {
    Ok(user) -> {
      let login_response = LoginResponse(token: token, user: user)
      let json_body = auth_transform.login_response_encoder(login_response)
      Ok(wisp.json_response(json.to_string(json_body), 200))
    }
    Error(wisp_response) -> Error(wisp_response)
  }
}

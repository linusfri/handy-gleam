import auth_server/auth/auth_utils
import auth_server/auth/types.{type LoginFormData, LoginResponse}
import auth_server/services/users/user_service
import auth_server/utils/api_client
import gleam/http/request as http_request
import gleam/json
import gleam/result
import glow_auth.{type Client, Client}
import glow_auth/token_request.{DefaultScope, RequestBody, client_credentials}
import glow_auth/uri/uri_builder.{RelativePath}
import wisp

fn create_client(client_id: String) -> Client(body) {
  let site = auth_utils.get_default_site_uri()

  Client(id: client_id, secret: "None", site: site)
}

pub fn build_login_request(
  login_form_data: LoginFormData,
) -> http_request.Request(String) {
  let client = create_client(login_form_data.client_id)
  let token_endpoint = RelativePath("token")
  let request_body = auth_utils.build_request_body(login_form_data.body)

  client_credentials(client, token_endpoint, RequestBody, DefaultScope)
  |> http_request.set_body(request_body)
}

pub fn build_login_response(form_data: LoginFormData) {
  let login_request = build_login_request(form_data)

  let token_response = case api_client.send_request(login_request) {
    Ok(res) ->
      case auth_utils.token_response_decoder(res) {
        Ok(token_response) -> Ok(token_response)
        Error(_) -> Error(wisp.json_response("Could not decode token", 500))
      }
    Error(wisp_error) -> Error(wisp_error)
  }

  use token <- result.try(token_response)
  use user_response <- result.try(user_service.get_user(token.access_token))

  case auth_utils.user_decoder(user_response) {
    Ok(user) -> {
      let login_response = LoginResponse(token: token, user: user)
      let json_body = auth_utils.login_response_encoder(login_response)
      Ok(wisp.json_response(json.to_string(json_body), 200))
    }
    Error(_) -> Error(wisp.json_response("Failed to decode user info", 500))
  }
}
